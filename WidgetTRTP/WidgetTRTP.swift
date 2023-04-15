//
//  WidgetTRTP.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import TroutLib
import TroutUI

struct WidgetTRTP: Widget {
    let kind: String = "WidgetTRTP"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Task Routines")
        .description("Time since last task routine.")
        .supportedFamilies([.systemSmall])
    }
}

struct WidgetTRTP_Previews: PreviewProvider {
    static var previews: some View {
        let entry = WidgetEntry(timeInterval: 1000)
        return WidgetView(entry: entry)
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
