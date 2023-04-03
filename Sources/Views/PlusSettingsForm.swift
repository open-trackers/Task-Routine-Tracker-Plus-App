//
//  PlusSettingsForm.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TrackerLib
import TrackerUI
import TroutLib
import TroutUI

struct PlusSettingsForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Views

    var body: some View {
        if let appSetting = try? AppSetting.getOrCreate(viewContext),
           let mainStore = manager.getMainStore(viewContext),
           let archiveStore = manager.getArchiveStore(viewContext)
        {
            TroutSettings(appSetting: appSetting, onRestoreToDefaults: {}) {
                ExportSettings(mainStore: mainStore,
                               archiveStore: archiveStore,
                               filePrefix: "grt-",
                               createZipArchive: troutCreateZipArchive)

                Button(action: {
                    router.path.append(TroutRoute.about)
                }) {
                    Text("About \(appName)")
                }
            }
        } else {
            Text("Settings not available.")
        }
    }

    // MARK: - Properties

    private var appName: String {
        Bundle.main.appName ?? "unknown"
    }
}

struct PlusSettingsForm_Previews: PreviewProvider {
    static var previews: some View {
        PlusSettingsForm()
    }
}
