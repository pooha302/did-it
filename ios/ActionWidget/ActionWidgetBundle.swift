//
//  ActionWidgetBundle.swift
//  ActionWidget
//
//  Created by pooha302 on 2/7/26.
//

import WidgetKit
import SwiftUI

@main
struct ActionWidgetBundle: WidgetBundle {
    var body: some Widget {
        ActionWidget()
        if #available(iOS 18.0, *) {
            ActionWidgetControl()
        }
        ActionWidgetLiveActivity()
    }
}
