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

    private let walkOptions: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20]

    private var outboundEnabled: Bool { appState.settings?.outboundEnabled ?? false }

    // MARK: - Body

    var body: some View {
        outboundObserved
            .sheet(isPresented: $showHomeStationPicker) {
                StationSearchModalView(title: "Home station", selectedStation: $homeStation, onDismiss: { showHomeStationPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showOfficeStationPicker) {
                StationSearchModalView(title: "Office station", selectedStation: $officeStation, onDismiss: { showOfficeStationPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
            }
            .sheet(isPresented: $showOutboundDestPicker) {
                StationSearchModalView(title: "Destination station", selectedStation: $outboundDestStation, onDismiss: { showOutboundDestPicker = false })
                    .environmentObject(store).preferredColorScheme(.light)
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
        .background(Color(hex: "FAFAFA").ignoresSafeArea())
    }

    private var header: some View {
        Text("Settings")
            .scaledFont(size: 40, weight: .bold)
            .tracking(-2)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
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

            Picker("Going to", selection: $outboundType) {
                Text("Home").tag(OutboundDestinationType.home)
                Text("Other place").tag(OutboundDestinationType.otherPlace)
            }
            .pickerStyle(.segmented)

            if outboundType == .otherPlace {
                SettingsCard(title: "Destination") {
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
            SettingsRow(label: label) {
                HStack(spacing: 8) {
                    if station.naptanId.isEmpty {
                        Text("Choose")
                            .typography(.large)
                            .foregroundColor(.grey30)
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(station.displayName)
                                .typography(.h4)
                                .foregroundColor(.black)
                                .lineLimit(1)
                            if !station.lineDisplayText.isEmpty {
                                Text(station.lineDisplayText)
                                    .typography(.footnote)
                                    .foregroundColor(.grey30)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Image(systemName: "chevron.right")
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(.grey30)
                }
            }
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Office days")
                .typography(.main)
                .foregroundColor(.grey50)
            HStack(spacing: 6) {
                DayChip(title: "Mon", isOn: $monday)
                DayChip(title: "Tue", isOn: $tuesday)
                DayChip(title: "Wed", isOn: $wednesday)
                DayChip(title: "Thu", isOn: $thursday)
                DayChip(title: "Fri", isOn: $friday)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 20)
        .overlay(alignment: .top) { Rectangle().fill(Color.grey10).frame(height: 1) }
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
        .padding(.horizontal, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.grey10, lineWidth: 1)
        )
    }
}

/// One divided row: grey label on the left, value on the right.
private struct SettingsRow<Value: View>: View {
    var label: String
    @ViewBuilder var value: () -> Value

    var body: some View {
        HStack(spacing: 12) {
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

/// Right-hand value text ("5 min", "9:00 am"). Dims while its picker is open.
private struct ValueChip: View {
    var text: String
    var isActive = false

    var body: some View {
        Text(text)
            .typography(.large)
            .foregroundColor(isActive ? .grey30 : .black)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(minWidth: 63, minHeight: 20)
    }
}

/// Weekday toggle: black when selected, grey10 otherwise.
private struct DayChip: View {
    var title: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(title)
                .typography(.main)
                .foregroundColor(isOn ? .white : .grey50)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(isOn ? Color.black : Color.grey10)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
