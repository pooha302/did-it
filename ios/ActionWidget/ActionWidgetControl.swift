//
//  ActionWidgetControl.swift
//  ActionWidget
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct ActionWidgetControl: ControlWidget {
    static let kind: String = "com.pooha302.didit.ActionWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetButton(action: IncrementIntent(actionId: value.id)) {
                Label(value.title, systemImage: "plus.circle.fill")
                    .tint(Color(hex: value.color))
            }
        }
        .displayName("Increment Action")
        .description("Quickly increment an action count from Control Center.")
    }
}

@available(iOS 18.0, *)
extension ActionWidgetControl {
    struct Value {
        var id: String
        var title: String
        var count: Int
        var color: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: SelectControlIntent) -> Value {
            Value(id: "preview", title: "Action", count: 0, color: "#38BDF8")
        }

        func currentValue(configuration: SelectControlIntent) async throws -> Value {
            let defaults = UserDefaults(suiteName: "group.com.pooha302.didit")
            
            // Resolve selected action or fallback to first active
            var targetId = ""
            if let action = configuration.action {
                targetId = action.id
            } else {
                let idsString = defaults?.string(forKey: "action_ids") ?? ""
                targetId = idsString.split(separator: ",").map(String.init).first ?? ""
            }
            
            let title = defaults?.string(forKey: "title_\(targetId)") ?? "Action"
            let count = defaults?.integer(forKey: "count_\(targetId)") ?? 0
            let color = defaults?.string(forKey: "color_\(targetId)") ?? "#38BDF8"
            
            return Value(id: targetId, title: title, count: count, color: color)
        }
    }
}
