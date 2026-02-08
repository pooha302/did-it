//
//  ActionWidgetLiveActivity.swift
//  ActionWidget
//
//  Created by pooha302 on 2/7/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ActionWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ActionWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ActionWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ActionWidgetAttributes {
    fileprivate static var preview: ActionWidgetAttributes {
        ActionWidgetAttributes(name: "World")
    }
}

extension ActionWidgetAttributes.ContentState {
    fileprivate static var smiley: ActionWidgetAttributes.ContentState {
        ActionWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ActionWidgetAttributes.ContentState {
         ActionWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ActionWidgetAttributes.preview) {
   ActionWidgetLiveActivity()
} contentStates: {
    ActionWidgetAttributes.ContentState.smiley
    ActionWidgetAttributes.ContentState.starEyes
}
