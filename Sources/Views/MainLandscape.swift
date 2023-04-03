//
//  MainLandscape.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TrackerUI
import TroutLib
import TroutUI

struct MainLandscape: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @SceneStorage(mainNavDataMRoutineKey) private var routineNavData: Data?
    @SceneStorage(mainNavDataHistoryKey) private var historyNavData: Data?

    var body: some View {
        HStack {
            TroutNavStack(navData: $routineNavData,
                          stackIdentifier: "Routines",
                          destination: destination)
            {
                MRoutineList()
            }

            TroutNavStack(navData: $historyNavData,
                          stackIdentifier: "History",
                          destination: destination)
            {
                PlusRecentRoutineRun(withSettings: true)
            }
        }
    }

    private func destination(router: TroutRouter, route: TroutRoute) -> some View {
        Destination(route: route)
            .environmentObject(router)
            .environment(\.managedObjectContext, viewContext)
    }
}

struct MainLandscape_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = MTask.create(ctx, routine: routine, userOrder: 0)
        e1.name = "Lat Pulldown"
        let e2 = MTask.create(ctx, routine: routine, userOrder: 1)
        e2.name = "Arm Curl"
        return MainLandscape()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
    }
}
