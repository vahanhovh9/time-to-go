import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: TFLDataStore
    var viewModel: MainViewModel

    // MARK: - Inbound state

    @State private var homeStation: TFLStopPoint = .placeholder
    @State private var homeWalkMinutes: Int = 5
    @State private var officeStation: TFLStopPoint = .placeholder
    @State private var officeWalkMinutes: Int = 5
    @State private var arrivalTime: Date = Self.time(9, 0)
    @State private var monday = false
    @State private var tuesday = true
    @State private var wednesday = false
    @State private var thursday = true
    @State private var friday = false

    @State private var showHomeStationPicker = false
    @State private var showOfficeStationPicker = false
    @State private var showOfficeDaysPicker = false

    // MARK: - Outbound state

    @State private var outboundArrivalTime: Date = Self.time(18, 0)
    @State private var outboundWalkMinutes: Int = 5
    @State private var outboundDestStation: TFLStopPoint = .placeholder
    @State private var showOutboundDestPicker = false
    /// Going back home or to another place; both keep their details.
    @State private var outboundType: OutboundDestinationType = .home

    /// Which time row currently has its wheel picker expanded.
    @State private var expandedTimeRow: String?
    @State private var isLoaded = false
    /// Settings save instantly; the TfL reload waits until the user pauses.
    @State private var reloadTask: Task<Void, Never>?

    private let walkOptions: [Int] = Array(1...25)

    private var outboundEnabled: Bool { appState.settings?.outboundEnabled ?? false }

    /// The office can't be the home station, or the Other place destination while it's in use.
    private var officeExclusions: [TFLStopPoint] {
        outboundType == .otherPlace ? [homeStation, outboundDestStation] : [homeStation]
    }

    // MARK: - Body

    var body: some View {
        outboundObserved
            .sheet(isPresented: $showHomeStationPicker) {
                StationSearchModalView(title: "Home station", selectedStation: $homeStation, excluding: [officeStation], onDismiss: { showHomeStationPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showOfficeStationPicker) {
                StationSearchModalView(title: "Office station", selectedStation: $officeStation, excluding: officeExclusions, onDismiss: { showOfficeStationPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showOutboundDestPicker) {
                StationSearchModalView(title: "Destination station", selectedStation: $outboundDestStation, excluding: [officeStation], onDismiss: { showOutboundDestPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showOfficeDaysPicker) {
                OfficeDaysSheet(
                    monday: $monday, tuesday: $tuesday, wednesday: $wednesday,
                    thursday: $thursday, friday: $friday,
                    onDone: { showOfficeDaysPicker = false }
                )
            }
    }

    // Split modifier chains into named layers so the type-checker resolves each independently.

    private var outboundObserved: some View {
        inboundObserved
            .onChange(of: outboundArrivalTime)      { _, _ in autoSave() }
            .onChange(of: outboundWalkMinutes)      { _, _ in autoSave() }
            .onChange(of: outboundDestStation)      { _, _ in autoSave() }
            .onChange(of: outboundType)             { _, newType in
                autoSave()
                // No station for the other place yet: ask for one straight away.
                if newType == .otherPlace, outboundDestStation.naptanId.isEmpty, isLoaded {
                    showOutboundDestPicker = true
                }
            }
    }

    private var inboundObserved: some View {
        baseView
            .onChange(of: monday)           { _, _ in autoSave() }
            .onChange(of: tuesday)          { _, _ in autoSave() }
            .onChange(of: wednesday)        { _, _ in autoSave() }
            .onChange(of: thursday)         { _, _ in autoSave() }
            .onChange(of: friday)           { _, _ in autoSave() }
    }

    private var baseView: some View {
        page
            .onAppear(perform: prefill)
            .onChange(of: homeStation)       { _, _ in autoSave() }
            .onChange(of: homeWalkMinutes)   { _, _ in autoSave() }
            .onChange(of: officeStation)     { _, _ in autoSave() }
            .onChange(of: officeWalkMinutes) { _, _ in autoSave() }
            .onChange(of: arrivalTime)       { _, _ in autoSave() }
    }

    // MARK: - Page

    private var page: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    toOfficeGroup
                    // Only once Back home is set up (from the Back home tab).
                    if outboundEnabled { backHomeGroup }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
        }
        .background(Color.brightBackground.ignoresSafeArea())
    }

    private var header: some View {
        Text("Settings")
            .scaledFont(size: 40, weight: .bold)
            .tracking(-2)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            #if DEBUG
            .overlay(alignment: .trailing) { DevMenuButton() }
            #endif
            .padding(.horizontal, 26)
            .padding(.top, 14)
            .padding(.bottom, 20)
    }

    // MARK: - To office

    private var toOfficeGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupTitle("To office")

            SettingsCard(title: "Home") {
                stationRow(label: "Station", station: homeStation) { showHomeStationPicker = true }
                walkRow(label: "Walk to station", minutes: $homeWalkMinutes)
            }

            SettingsCard(title: "Office") {
                stationRow(label: "Station", station: officeStation) { showOfficeStationPicker = true }
                walkRow(label: "Walk from station", minutes: $officeWalkMinutes)
            }

            SettingsCard(title: "Schedule") {
                timeRow(id: "inboundArrival", label: "Office arrival", time: $arrivalTime)
                daysRow
            }
        }
    }

    // MARK: - Back home

    private var backHomeGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            groupTitle("Back home")

            SettingsCard(title: "Destination") {
                goingToRow
                // Home's station and walk come from the Home card above.
                if outboundType == .otherPlace {
                    stationRow(label: "Station", station: outboundDestStation) { showOutboundDestPicker = true }
                    walkRow(label: "Walk from station", minutes: $outboundWalkMinutes)
                }
            }
            SettingsCard(title: "Schedule") {
                timeRow(id: "outboundArrival", label: "Arrival time", time: $outboundArrivalTime)
            }
        }
    }

    private func groupTitle(_ title: String) -> some View {
        Text(title)
            .typography(.h2)
            .foregroundColor(.black)
            .padding(.leading, 6)
    }

    // MARK: - Rows

    private func stationRow(label: String, station: TFLStopPoint, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            SettingsRow(label: label, alignment: .firstTextBaseline) {
                if station.naptanId.isEmpty {
                    ValueChip(text: "Choose", isActive: true)
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Chevron belongs to the station name, not the two-line block.
                        HStack(alignment: .firstTextBaseline, spacing: RowChevron.gap) {
                            Text(station.displayName)
                                .typography(.h4)
                                .foregroundColor(.black)
                                .lineLimit(1)
                            RowChevron()
                                // Centred on the name's capitals, keeping its baseline
                                // level with the row label.
                                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5.5 }
                        }
                        if !station.lineDisplayText.isEmpty {
                            LineLabel(station: station)
                                // Lines up under the station name, left of the chevron.
                                .padding(.trailing, RowChevron.width + RowChevron.gap)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Picks one option, so a native menu rather than tabs; the whole row opens it.
    private var goingToRow: some View {
        Menu {
            Picker("Going to", selection: $outboundType) {
                Text("Home").tag(OutboundDestinationType.home)
                Text("Other place").tag(OutboundDestinationType.otherPlace)
            }
        } label: {
            SettingsRow(label: "Going to") {
                ValueChip(text: outboundType == .home ? "Home" : "Other place")
            }
        }
    }

    private func walkRow(label: String, minutes: Binding<Int>) -> some View {
        SettingsRow(label: label) {
            Menu {
                Picker(label, selection: minutes) {
                    ForEach(walkOptions, id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
            } label: {
                ValueChip(text: "\(minutes.wrappedValue) min")
            }
        }
    }

    private func timeRow(id: String, label: String, time: Binding<Date>) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedTimeRow = expandedTimeRow == id ? nil : id
                }
            } label: {
                SettingsRow(label: label) {
                    ValueChip(text: Self.timeFormatter.string(from: time.wrappedValue),
                              isActive: expandedTimeRow == id)
                }
            }
            .buttonStyle(.plain)

            if expandedTimeRow == id {
                DatePicker(label, selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }
        }
    }

    private var daysRow: some View {
        Button { showOfficeDaysPicker = true } label: {
            SettingsRow(label: "Office days") {
                ValueChip(text: officeDaysText, isActive: showOfficeDaysPicker)
            }
        }
        .buttonStyle(.plain)
    }

    /// "Tu, Th"; every day shows, as there are at most five.
    private var officeDaysText: String {
        let days = [(monday, "Mo"), (tuesday, "Tu"), (wednesday, "We"), (thursday, "Th"), (friday, "Fr")]
        let chosen = days.filter(\.0).map(\.1)
        return chosen.isEmpty ? "Choose" : chosen.joined(separator: ", ")
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }()

    // MARK: - Prefill / Save

    private func prefill() {
        guard let s = appState.settings else { return }
        homeStation       = TFLStopPoint(naptanId: s.homeStationId,   commonName: s.homeStationName,   lines: s.homeStationLines)
        homeWalkMinutes   = max(1, s.walkingMinutesToStation)
        officeStation     = TFLStopPoint(naptanId: s.officeStationId, commonName: s.officeStationName, lines: s.officeStationLines)
        officeWalkMinutes = max(1, s.walkingMinutesToOffice)
        arrivalTime       = s.arrivalTime
        let days = Set(s.officeDays)
        monday    = days.contains(.monday)
        tuesday   = days.contains(.tuesday)
        wednesday = days.contains(.wednesday)
        thursday  = days.contains(.thursday)
        friday    = days.contains(.friday)
        outboundArrivalTime      = s.outboundArrivalTime
        outboundWalkMinutes      = max(1, s.outboundWalkingTimeFromStation)
        outboundType             = s.outboundDestinationType
        // The other place's details are kept even while Home is selected.
        if !s.outboundDestinationStationId.isEmpty {
            outboundDestStation = TFLStopPoint(
                naptanId: s.outboundDestinationStationId,
                commonName: s.outboundDestinationStationName,
                lines: s.outboundDestinationStationLines
            )
        }
        DispatchQueue.main.async { isLoaded = true }
    }

    private func autoSave() {
        guard isLoaded, var s = appState.settings else { return }
        s.homeStationId           = homeStation.naptanId
        s.homeStationName         = homeStation.commonName
        s.homeStationLines        = homeStation.lines
        s.walkingMinutesToStation = homeWalkMinutes
        s.officeStationId         = officeStation.naptanId
        s.officeStationName       = officeStation.commonName
        s.officeStationLines      = officeStation.lines
        s.walkingMinutesToOffice  = officeWalkMinutes
        s.arrivalTime             = arrivalTime
        var days: [Weekday] = []
        if monday    { days.append(.monday) }
        if tuesday   { days.append(.tuesday) }
        if wednesday { days.append(.wednesday) }
        if thursday  { days.append(.thursday) }
        if friday    { days.append(.friday) }
        s.officeDays = days
        if s.outboundEnabled {
            s.outboundArrivalTime             = outboundArrivalTime
            s.outboundDestinationType         = outboundType
            // Saved whichever is selected, so switching back to Other place restores them.
            s.outboundWalkingTimeFromStation  = outboundWalkMinutes
            s.outboundDestinationStationId    = outboundDestStation.naptanId
            s.outboundDestinationStationName  = outboundDestStation.commonName
            s.outboundDestinationStationLines = outboundDestStation.lines
        }
        appState.updateSettings(s)
        reloadTask?.cancel()
        reloadTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            viewModel.updateSettings(s)
        }
    }

    private static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    let settings = UserSettings()
    let vm = MainViewModel(
        settings: settings,
        calculationService: CommuteCalculationService(tflService: MockTFLService())
    )
    return SettingsView(viewModel: vm)
        .environmentObject(AppState())
        .environmentObject(TFLDataStore(service: MockTFLService()))
}

// MARK: - Building blocks (same card / row language as DepartureBoard)

/// Bordered card with an H3 title, optional footnote subtitle, and divided rows.
private struct SettingsCard<Rows: View>: View {
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var rows: () -> Rows

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .typography(.h3)
                    .foregroundColor(.black)
                if let subtitle {
                    Text(subtitle)
                        .typography(.footnote)
                        .foregroundColor(.grey30)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) { rows() }
        }
        .padding(.top, 16)
        .padding(.bottom, subtitle == nil ? 0 : 16)
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radius.smallBlock))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.smallBlock)
                .stroke(Color.grey10, lineWidth: 1)
        )
    }
}

/// One divided row: grey label on the left, value on the right.
private struct SettingsRow<Value: View>: View {
    var label: String
    /// `.firstTextBaseline` lines the label up with the value's first line (station rows).
    var alignment: VerticalAlignment = .center
    @ViewBuilder var value: () -> Value

    var body: some View {
        HStack(alignment: alignment, spacing: 12) {
            Text(label)
                .typography(.large)
                .foregroundColor(.grey30)
            Spacer(minLength: 8)
            value()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 20)
        .contentShape(Rectangle())
        .overlay(alignment: .top) { Rectangle().fill(Color.grey10).frame(height: 1) }
    }
}

/// Right-hand value ("5 min", "9:00 am", "Choose") with the chevron every changeable value
/// has. Dims while its picker is open.
private struct ValueChip: View {
    var text: String
    var isActive = false

    var body: some View {
        HStack(spacing: RowChevron.gap) {
            Text(text)
                .typography(.large)
                .foregroundColor(isActive ? .grey30 : .black)
                .lineLimit(1)
            RowChevron()
        }
    }
}

/// Trailing chevron on rows whose value can be changed.
private struct RowChevron: View {
    static let width: CGFloat = 8
    static let gap: CGFloat = 8

    var body: some View {
        Image(systemName: "chevron.right")
            .scaledFont(size: 12, weight: .semibold)
            .foregroundColor(.grey30)
            .frame(width: Self.width)
            .accessibilityHidden(true)
    }
}

/// "● Northern line": a 6pt dot in the line's colour for each line named in the text.
private struct LineLabel: View {
    let station: TFLStopPoint

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(station.lines.prefix(2), id: \.id) { line in
                    Circle()
                        .fill(Color.tflLine(line.id))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)
            Text(station.lineDisplayText)
                .typography(.footnote)
                .foregroundColor(.grey30)
                .lineLimit(1)
        }
    }
}

/// Office days picker: the same radios as setup. Changes save as they're made.
private struct OfficeDaysSheet: View {
    @Binding var monday: Bool
    @Binding var tuesday: Bool
    @Binding var wednesday: Bool
    @Binding var thursday: Bool
    @Binding var friday: Bool
    var onDone: () -> Void

    /// As in setup: at least one day, or there's no commute to work out.
    private var hasDay: Bool { monday || tuesday || wednesday || thursday || friday }

    var body: some View {
        NavigationView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                DayPicker(day: "Mon", isSelected: $monday)
                DayPicker(day: "Tue", isSelected: $tuesday)
                DayPicker(day: "Wed", isSelected: $wednesday)
                DayPicker(day: "Thu", isSelected: $thursday)
                DayPicker(day: "Fri", isSelected: $friday)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.white)
            .navigationTitle("Office days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDone)
                        .disabled(!hasDay)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(Color.black)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.light)
        .presentationDetents([.height(300)])
        .interactiveDismissDisabled(!hasDay)
    }
}
