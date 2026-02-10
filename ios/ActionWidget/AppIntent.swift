//
//  AppIntent.swift
//  ActionWidget
//

import WidgetKit
import AppIntents

// 1. Data Model for AppEntity
struct ActionEntity: AppEntity, Identifiable {
    var id: String
    var title: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Action"
    static var defaultQuery = ActionQuery()
            
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

// 2. Query for AppEntity
struct ActionQuery: EntityQuery {
    private func fetchActionEntities(for identifiers: [String]) async -> [ActionEntity] {
        let groupDefaults = UserDefaults(suiteName: "group.com.pooha302.didit")
        let standardDefaults = UserDefaults.standard
        
        // Handle "none" ID
        if identifiers.contains("none") {
            // We'll filter it out later or handle it specially if needed, 
            // but suggestedEntities will add it.
        }
        
        // 1. Load all synced action data from JSON as primary source
        var titleMap: [String: String] = [:]
        if let jsonString = groupDefaults?.string(forKey: "actions_json") ?? standardDefaults.string(forKey: "actions_json"),
           let jsonData = jsonString.data(using: .utf8),
           let syncedActions = try? JSONDecoder().decode([ActionSyncData].self, from: jsonData) {
            for action in syncedActions {
                titleMap[action.id] = action.title
            }
        }
        
        return identifiers.map { id in
            if id == "none" {
                return ActionEntity(id: "none", title: LocalizationHelpers.localizedString("Action_None"))
            }
            // Use JSON title, then fall back to individual keys, then fallback to capitalized ID
            let title = titleMap[id] ?? groupDefaults?.string(forKey: "title_\(id)") ?? standardDefaults.string(forKey: "title_\(id)") ?? id.capitalized
            return ActionEntity(id: id, title: title)
        }
    }

    func entities(for identifiers: [String]) async throws -> [ActionEntity] {
        return await fetchActionEntities(for: identifiers)
    }
    
    func suggestedEntities() async throws -> [ActionEntity] {
        let groupDefaults = UserDefaults(suiteName: "group.com.pooha302.didit")
        let standardDefaults = UserDefaults.standard
        
        var allIds: [String] = []
        
        // 1. Get IDs from JSON
        if let jsonString = groupDefaults?.string(forKey: "actions_json") ?? standardDefaults.string(forKey: "actions_json"),
           let jsonData = jsonString.data(using: .utf8),
           let syncedActions = try? JSONDecoder().decode([ActionSyncData].self, from: jsonData) {
            allIds = syncedActions.map { $0.id }
        }
        
        // 2. Fallback IDs
        if allIds.isEmpty {
            let idsString = groupDefaults?.string(forKey: "action_ids") ?? standardDefaults.string(forKey: "action_ids") ?? ""
            if !idsString.isEmpty {
                allIds = idsString.split(separator: ",").map(String.init)
            }
        }
        
        // 3. Fallback to active action ID
        if allIds.isEmpty {
            if let activeId = groupDefaults?.string(forKey: "active_action_id") ?? standardDefaults.string(forKey: "active_action_id") {
                allIds = [activeId]
            }
        }
        
        // 4. Fallback search
        if allIds.isEmpty {
            let groupKeys = groupDefaults?.dictionaryRepresentation().keys.filter { $0.hasPrefix("title_") }.map { String($0.dropFirst(6)) } ?? []
            let standardKeys = standardDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("title_") }.map { String($0.dropFirst(6)) } ?? []
            allIds = Array(Set(groupKeys + standardKeys)).sorted()
        }
        
        let entities = await fetchActionEntities(for: allIds)
        
        var results: [ActionEntity] = []
        
        // Add "None" option at the BEGINNING
        results.append(ActionEntity(id: "none", title: LocalizationHelpers.localizedString("Action_None")))
        results.append(contentsOf: entities)
        
        // ONLY show defaults if we have NO synced actions
        if entities.isEmpty {
            results = [
                ActionEntity(id: "none", title: LocalizationHelpers.localizedString("Action_None")),
                ActionEntity(id: "coffee", title: "Coffee"),
                ActionEntity(id: "water", title: "Water"),
                ActionEntity(id: "pill", title: "Pill"),
                ActionEntity(id: "exercise", title: "Exercise"),
                ActionEntity(id: "snack", title: "Snack")
            ]
        }
        
        return results
    }
    
    func defaultResult() async -> ActionEntity? {
        try? await suggestedEntities().first
    }
}

// 3. Configuration Intent for Home Screen Widgets
struct SelectActionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "SelectAction_Title"
    static var description: IntentDescription = IntentDescription("SelectAction_Desc")
    
    @Parameter(title: "Action_Label")
    var action: ActionEntity?
    
    @Parameter(title: "Action2_Label")
    var action2: ActionEntity?
    
    @Parameter(title: "Action3_Label")
    var action3: ActionEntity?
    
    @Parameter(title: "Action4_Label")
    var action4: ActionEntity?
}

// 4. Configuration Intent for Control Center (iOS 18)
@available(iOS 18.0, *)
struct SelectControlIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Select Action to Control"
    
    @Parameter(title: "Action")
    var action: ActionEntity?
}

// 5. Interaction Intent (Increment Count)
struct IncrementIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Count"
    
    @Parameter(title: "Action ID")
    var actionId: String
    
    init() {}
    
    init(actionId: String) {
        self.actionId = actionId
    }
    
    func perform() async throws -> some IntentResult {
        let groupDefaults = UserDefaults(suiteName: "group.com.pooha302.didit")
        let standardDefaults = UserDefaults.standard
        
        // Update count in UserDefaults
        let currentCount = groupDefaults?.integer(forKey: "count_\(actionId)") ?? 0
        let newCount = currentCount + 1
        groupDefaults?.set(newCount, forKey: "count_\(actionId)")
        
        // Update lastTapTime in UserDefaults
        let now = ISO8601DateFormatter().string(from: Date())
        groupDefaults?.set(now, forKey: "lastTapTime_\(actionId)")
        
        // Update action_states_v2 JSON for app sync
        if let statesString = standardDefaults.string(forKey: "action_states_v2"),
           let statesData = statesString.data(using: .utf8),
           var states = try? JSONSerialization.jsonObject(with: statesData) as? [String: [String: Any]] {
            
            if var actionState = states[actionId] {
                actionState["count"] = newCount
                actionState["lastTapTime"] = now
                states[actionId] = actionState
                
                if let updatedData = try? JSONSerialization.data(withJSONObject: states),
                   let updatedString = String(data: updatedData, encoding: .utf8) {
                    standardDefaults.set(updatedString, forKey: "action_states_v2")
                }
            }
        }
        
        // Signal WidgetKit to reload all timelines
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
