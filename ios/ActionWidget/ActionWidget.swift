import WidgetKit
import SwiftUI
import AppIntents

// Simple data structure for entry list
struct ActionEntryData: Hashable {
    let id: String
    let title: String
    let count: Int
    let goal: Int
    let color: String
}

// Data for JSON sync
struct ActionSyncData: Codable {
    let id: String
    let title: String
    let count: Int
    let goal: Int
    let color: String
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), 
                    id: "coffee", 
                    title: "Coffee", 
                    count: 3, 
                    goal: 5, 
                    color: "#38BDF8", 
                    allActions: [], 
                    displayActions: [ActionEntryData(id: "coffee", title: "Coffee", count: 3, goal: 5, color: "#38BDF8")],
                    language: "en")
    }

    func snapshot(for configuration: SelectActionIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), 
                    id: "coffee", 
                    title: "Coffee", 
                    count: 3, 
                    goal: 5, 
                    color: "#38BDF8", 
                    allActions: [], 
                    displayActions: [ActionEntryData(id: "coffee", title: "Coffee", count: 3, goal: 5, color: "#38BDF8")],
                    language: "en")
    }

    func timeline(for configuration: SelectActionIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let groupDefaults = UserDefaults(suiteName: "group.com.pooha302.didit")
        
        // 1. Fetch All Actions from Group
        var allActions: [ActionEntryData] = []
        
        if let jsonString = groupDefaults?.string(forKey: "actions_json"),
           let jsonData = jsonString.data(using: .utf8) {
            do {
                let syncedActions = try JSONDecoder().decode([ActionSyncData].self, from: jsonData)
                allActions = syncedActions.map { ActionEntryData(id: $0.id, title: $0.title, count: $0.count, goal: $0.goal, color: $0.color) }
            } catch {
                print("WIDGET: JSON decode failed: \(error)")
            }
        }
        
        if allActions.isEmpty {
            let idsString = groupDefaults?.string(forKey: "action_ids") ?? ""
            let allIds = idsString.split(separator: ",").map(String.init)
            allActions = allIds.map { id in
                let title = groupDefaults?.string(forKey: "title_\(id)") ?? id.capitalized
                let color = groupDefaults?.string(forKey: "color_\(id)") ?? "#38BDF8"
                return ActionEntryData(id: id, title: title, count: 0, goal: 0, color: color)
            }
        }
        
        if allActions.isEmpty {
            allActions = [ActionEntryData(id: "coffee", title: "Coffee", count: 0, goal: 3, color: "#38BDF8")]
        }
        
        // 2. REFRESH Counts and Goals from Individual Keys (shared via Group)
        allActions = allActions.map { action in
            var finalCount = action.count
            var finalGoal = action.goal
            
            if let countSum = groupDefaults?.object(forKey: "count_\(action.id)") as? NSNumber {
                finalCount = countSum.intValue
            }
            if let goalSum = groupDefaults?.object(forKey: "goal_\(action.id)") as? NSNumber {
                finalGoal = goalSum.intValue
            }
            
            return ActionEntryData(id: action.id, title: action.title, count: finalCount, goal: finalGoal, color: action.color)
        }
        
        // 3. Determine Selected Actions for all slots
        var displayIds: [String] = []
        
        // Slot 1: Default to active only if never configured
        if let action = configuration.action {
            if action.id != "none" {
                displayIds.append(action.id)
            }
            // If it IS "none", it remains empty (displayIds doesn't get it)
        } else {
            // Never configured -> Fallback to active
            let activeId = groupDefaults?.string(forKey: "active_action_id") ?? allActions.first?.id ?? "coffee"
            displayIds.append(activeId)
        }
        
        // Slot 2, 3, 4: Optional (don't show if none)
        let otherSlots = [configuration.action2, configuration.action3, configuration.action4]
        for slot in otherSlots {
            if let id = slot?.id, id != "none" {
                displayIds.append(id)
            }
        }
        
        let displayActions = displayIds.compactMap { id in allActions.first(where: { $0.id == id }) }
        
        // Primary action (for Small widget)
        let targetId = displayIds.first ?? "coffee"
        let targetAction = allActions.first(where: { $0.id == targetId }) ?? allActions.first!
        
        let lang = groupDefaults?.string(forKey: "language_code") ?? "en"
        
        let entry = SimpleEntry(date: Date(), 
                                id: targetId, 
                                title: targetAction.title, 
                                count: targetAction.count, 
                                goal: targetAction.goal, 
                                color: targetAction.color, 
                                allActions: allActions,
                                displayActions: displayActions,
                                language: lang)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let id: String
    let title: String
    let count: Int
    let goal: Int
    let color: String
    let allActions: [ActionEntryData]
    let displayActions: [ActionEntryData]
    let language: String
}

struct ActionWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            let itemsToShow = entry.displayActions
            
            if itemsToShow.isEmpty {
                // Empty State: Configuration is all "None"
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    Text(String(localized: "Action_Empty_State"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if family == .systemSmall {
                // Small Widget: Single Action (High Visibility)
                ZStack {
                    if let primaryAction = itemsToShow.first {
                        LargeActionView(action: primaryAction)
                    } else {
                        LargeActionView(action: ActionEntryData(id: entry.id, title: entry.title, count: entry.count, goal: entry.goal, color: entry.color))
                    }
                }
                .padding(4)
            } else {
                // Medium Widget: 2x2 Grid (All 4 actions)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ActionRowItem(action: itemsToShow.indices.contains(0) ? itemsToShow[0] : nil)
                        ActionRowItem(action: itemsToShow.indices.contains(1) ? itemsToShow[1] : nil)
                    }
                    HStack(spacing: 8) {
                        ActionRowItem(action: itemsToShow.indices.contains(2) ? itemsToShow[2] : nil)
                        ActionRowItem(action: itemsToShow.indices.contains(3) ? itemsToShow[3] : nil)
                    }
                }
                .padding(12)
            }
        }
        .environment(\.locale, Locale(identifier: entry.language))
        .containerBackground(Color(hex: "#1A1A1A"), for: .widget)
    }
}

struct LargeActionView: View {
    let action: ActionEntryData
    
    var body: some View {
        Button(intent: IncrementIntent(actionId: action.id)) {
            VStack(spacing: 2) {
                Text(action.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#999999"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text("\(action.count)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText(value: Double(action.count)))
                    
                    if action.goal > 0 {
                        Text("/ \(action.goal)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#888888"))
                            .padding(.bottom, 4)
                    }
                }
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: action.color))
                    .frame(width: 32, height: 4)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#262626"))
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ActionRowItem: View {
    let action: ActionEntryData?
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            if let action = action {
                Button(intent: IncrementIntent(actionId: action.id)) {
                    HStack(spacing: family == .systemSmall ? 4 : 8) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: action.color))
                            .frame(width: 3, height: family == .systemSmall ? 20 : 28)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(action.title)
                                .font(.system(size: family == .systemSmall ? 8 : 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#999999"))
                                .lineLimit(1)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 1) {
                                Text("\(action.count)")
                                    .font(.system(size: family == .systemSmall ? 14 : 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText(value: Double(action.count)))
                                
                                if action.goal > 0 {
                                    Text("/\(action.goal)")
                                        .font(.system(size: family == .systemSmall ? 8 : 11, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#666666"))
                                }
                            }
                        }
                        Spacer(minLength: 0)
                        
                        if family != .systemSmall {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, family == .systemSmall ? 6 : 10)
                    .padding(.vertical, family == .systemSmall ? 6 : 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#262626"))
                    .cornerRadius(family == .systemSmall ? 8 : 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ActionWidget: Widget {
    let kind: String = "ActionWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectActionIntent.self, provider: Provider()) { entry in
            ActionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("DiditWidget_Name", defaultValue: "Did it Widget"))
        .description(LocalizedStringResource("DiditWidget_Desc", defaultValue: "Today's progress at a glance."))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
