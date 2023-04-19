//
//  TaskRunList.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import Compactor
import Tabler

import TrackerLib
import TrackerUI
import TroutLib
import TroutUI

struct TaskRunList<Header: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.managedObjectContext) private var viewContext

    typealias Sort = TablerSort<ZTaskRun>
    typealias Context = TablerContext<ZTaskRun>
    typealias ProjectedValue = ObservedObject<ZTaskRun>.Wrapper

    // MARK: - Parameters

    private var zRoutineRun: ZRoutineRun
    private var inStore: NSPersistentStore
    private var tableHeader: () -> Header

    init(zRoutineRun: ZRoutineRun,
         inStore: NSPersistentStore,
         tableHeader: @escaping () -> Header = { EmptyView() })
    {
        self.zRoutineRun = zRoutineRun
        self.inStore = inStore
        self.tableHeader = tableHeader

        let predicate = ZTaskRun.getPredicate(zRoutineRun: zRoutineRun, userRemoved: false)
        let sortDescriptors = ZTaskRun.byCompletedAt(ascending: true)
        let request = makeRequest(ZTaskRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: inStore)

        _taskRuns = FetchRequest<ZTaskRun>(fetchRequest: request)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskRunList.self))

    private let columnSpacing: CGFloat = 10

    private var columnPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        // EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
    }

    @FetchRequest private var taskRuns: FetchedResults<ZTaskRun>

    private var listConfig: TablerListConfig<ZTaskRun> {
        TablerListConfig<ZTaskRun>(
            onDelete: userRemoveAction
        )
    }

    private var gridItems: [GridItem] { [
        GridItem(.flexible(minimum: 70), spacing: columnSpacing, alignment: .leading),
        GridItem(.flexible(minimum: 120), spacing: columnSpacing, alignment: .leading),
//        GridItem(.flexible(minimum: 80), spacing: columnSpacing, alignment: .trailing),
    ] }

    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()

    private let tc = TimeCompactor(ifZero: "", style: .full, roundSmallToWhole: false)

    // MARK: - Views

    var body: some View {
        TablerList(listConfig,
                   header: header,
                   footer: footer,
                   row: listRow,
                   rowBackground: rowBackground,
                   results: taskRuns)
            .listStyle(.plain)
//            .navigationTitle(navigationTitle)
    }

    @ViewBuilder
    private func header(ctx _: Binding<Context>) -> some View {
        tableHeader()
        LazyVGrid(columns: gridItems, alignment: .leading) {
            Text("Elapsed")
                .padding(columnPadding)
            Text("Task")
                .padding(columnPadding)
//            Text("Intensity")
//                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func listRow(element: ZTaskRun) -> some View {
        LazyVGrid(columns: gridItems, alignment: .leading) {
            elapsedText(element.completedAt)
                .padding(columnPadding)
            Text(element.zTask?.name ?? "")
                .padding(columnPadding)
//            intensityText(element.intensity, element.zTask?.units)
//                .padding(columnPadding)
        }
    }

    @ViewBuilder
    private func footer(ctx _: Binding<Context>) -> some View {
        HStack {
            GroupBox {
                startedAtText
                    .lineLimit(1)
            } label: {
                Text("Started")
                    .foregroundStyle(.tint)
                    .padding(.bottom, 3)
            }
            GroupBox {
                durationText(zRoutineRun.elapsedSecs)
                    .lineLimit(1)
            } label: {
                Text("Duration")
                    .foregroundStyle(.tint)
                    .padding(.bottom, 3)
            }
        }
    }

    private func rowBackground(_: ZTaskRun) -> some View {
        EntityBackground(taskColorDarkBg)
    }

    private var startedAtText: some View {
        VStack {
            if let startedAt = zRoutineRun.startedAt,
               case let dateStr = df.string(from: startedAt)
            {
                Text(dateStr)
            } else {
                EmptyView()
            }
        }
    }

    private func elapsedText(_ completedAt: Date?) -> some View {
        ElapsedTimeText(elapsedSecs: getDuration(completedAt) ?? 0, timeElapsedFormat: timeElapsedFormat)
    }

    private func durationText(_ duration: TimeInterval) -> some View {
        Text(tc.string(from: duration as NSNumber) ?? "")
    }

    // MARK: - Properties

    // select a formatter to accommodate the duration
    private var timeElapsedFormat: TimeElapsedFormat {
        let secondsPerHour: TimeInterval = 3600
        return zRoutineRun.elapsedSecs < secondsPerHour ? .mm_ss : .hh_mm_ss
    }

    // MARK: - Actions

    // NOTE: 'removes' matching records, where present, from both mainStore and archiveStore.
    private func userRemoveAction(at offsets: IndexSet) {
        do {
            for index in offsets {
                let zTaskRun = taskRuns[index]

                guard let taskArchiveID = zTaskRun.zTask?.taskArchiveID,
                      let completedAt = zTaskRun.completedAt
                else { continue }

                try ZTaskRun.userRemove(viewContext, taskArchiveID: taskArchiveID, completedAt: completedAt)
            }

            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func getDuration(_ completedAt: Date?) -> TimeInterval? {
        guard let startedAt = zRoutineRun.startedAt,
              let completedAt
        else { return nil }

        return completedAt.timeIntervalSince(startedAt)
    }
}

struct TaskRunList_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let archiveStore = manager.getArchiveStore(ctx)!

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let zR = ZRoutine.create(ctx, routineArchiveID: routineArchiveID, routineName: "blah", toStore: archiveStore)
        let zRR = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, elapsedSecs: duration1, toStore: archiveStore)
        let taskArchiveID1 = UUID()
        let taskArchiveID2 = UUID()
        let taskArchiveID3 = UUID()
        let completedAt1 = startedAt1.addingTimeInterval(116)
        let completedAt2 = completedAt1.addingTimeInterval(173)
        let completedAt3 = completedAt1.addingTimeInterval(210)
        let zE1 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID1, taskName: "Lat Pulldown", toStore: archiveStore)
        let zE2 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID2, taskName: "Rear Delt", toStore: archiveStore)
        let zE3 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID3, taskName: "Arm Curl", toStore: archiveStore)
        _ = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE1, completedAt: completedAt1, toStore: archiveStore)
        let er2 = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE2, completedAt: completedAt2, toStore: archiveStore)
        _ = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE3, completedAt: completedAt3, toStore: archiveStore)
        er2.userRemoved = true
        try! ctx.save()

        return NavigationStack {
            TaskRunList(zRoutineRun: zRR, inStore: archiveStore)
                .environment(\.managedObjectContext, ctx)
        }
    }
}
