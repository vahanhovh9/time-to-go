import SwiftUI

// Concrete View type for group-label section headers — avoids @ViewBuilder type-inference overload.
private struct GroupSectionHeader: View {
    let groupTitle: String
    let sectionLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(groupTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .textCase(nil)
            if let label = sectionLabel {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.3)
            }
        }
        .padding(.top, 12)
    }
}

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
    @State private var notificationTime: Date = Self.time(7, 30)

    @State private var showHomeStationPicker = false
    @State private var showOfficeStationPicker = false

    // MARK: - Outbound state

    @State private var outboundArrivalTime: Date = Self.time(18, 0)
    @State private var outboundNotificationTime: Date = Self.time(16, 0)
    @State private var outboundWalkMinutes: Int = 5
    @State private var outboundDestStation: TFLStopPoint = .placeholder
    @State private var showOutboundDestPicker = false

    @State private var isLoaded = false

    private let walkOptions: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20]

    private var outboundEnabled: Bool { appState.settings?.outboundEnabled ?? false }
    private var outboundDestType: OutboundDestinationType { appState.settings?.outboundDestinationType ?? .home }

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
            .onChange(of: outboundNotificationTime) { _, _ in autoSave() }
            .onChange(of: outboundWalkMinutes)      { _, _ in autoSave() }
            .onChange(of: outboundDestStation)      { _, _ in autoSave() }
    }

    private var inboundObserved: some View {
        baseView
            .onChange(of: monday)           { _, _ in autoSave() }
            .onChange(of: tuesday)          { _, _ in autoSave() }
            .onChange(of: wednesday)        { _, _ in autoSave() }
            .onChange(of: thursday)         { _, _ in autoSave() }
            .onChange(of: friday)           { _, _ in autoSave() }
            .onChange(of: notificationTime) { _, _ in autoSave() }
    }

    private var baseView: some View {
        NavigationView { mainForm }
            .navigationViewStyle(.stack)
            .tint(.black)
            .onAppear(perform: prefill)
            .onChange(of: homeStation)       { _, _ in autoSave() }
            .onChange(of: homeWalkMinutes)   { _, _ in autoSave() }
            .onChange(of: officeStation)     { _, _ in autoSave() }
            .onChange(of: officeWalkMinutes) { _, _ in autoSave() }
            .onChange(of: arrivalTime)       { _, _ in autoSave() }
    }

    // MARK: - Form

    private var mainForm: some View {
        Form {
            homeSection
            officeSection
            scheduleSection
            inboundNotificationSection
            outboundContent
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Inbound sections (each is a concrete Section — no @ViewBuilder needed)

    private var homeSection: some View {
        Section {
            stationRow(label: "Station", station: homeStation, onTap: { showHomeStationPicker = true })
            walkPicker(label: "Walk to station", minutes: $homeWalkMinutes)
        } header: {
            GroupSectionHeader(groupTitle: "Inbound", sectionLabel: "Home")
        }
    }

    private var officeSection: some View {
        Section("Office") {
            stationRow(label: "Station", station: officeStation, onTap: { showOfficeStationPicker = true })
            walkPicker(label: "Walk from station", minutes: $officeWalkMinutes)
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            timePicker(label: "Office arrival", time: $arrivalTime)
            Toggle("Monday",    isOn: $monday)
            Toggle("Tuesday",   isOn: $tuesday)
            Toggle("Wednesday", isOn: $wednesday)
            Toggle("Thursday",  isOn: $thursday)
            Toggle("Friday",    isOn: $friday)
        }
    }

    private var inboundNotificationSection: some View {
        Section("Notification") {
            timePicker(label: "For office", time: $notificationTime)
        }
    }

    // MARK: - Outbound sections

    @ViewBuilder
    private var outboundContent: some View {
        if outboundEnabled {
            outboundScheduleSection     // includes the "Outbound" group header
            outboundNotificationSection
        } else {
            outboundDisabledSection
        }
    }

    // Handles both destination-type layouts; always shows the "Outbound" group header.
    @ViewBuilder
    private var outboundScheduleSection: some View {
        if outboundDestType == .otherPlace {
            Section {
                stationRow(label: "Station", station: outboundDestStation, onTap: { showOutboundDestPicker = true })
                walkPicker(label: "Walk from station", minutes: $outboundWalkMinutes)
            } header: {
                GroupSectionHeader(groupTitle: "Outbound", sectionLabel: "Destination")
            }
            Section("Schedule") {
                timePicker(label: "Arrival time", time: $outboundArrivalTime)
            }
        } else {
            Section {
                timePicker(label: "Arrival time", time: $outboundArrivalTime)
            } header: {
                GroupSectionHeader(groupTitle: "Outbound", sectionLabel: "Schedule")
            }
        }
    }

    private var outboundNotificationSection: some View {
        Section("Notification") {
            timePicker(label: "Notification time", time: $outboundNotificationTime)
        }
    }

    private var outboundDisabledSection: some View {
        Section {
            Text("Set up outbound from the Outbound tab.")
                .foregroundColor(.secondary)
                .font(.subheadline)
        } header: {
            GroupSectionHeader(groupTitle: "Outbound", sectionLabel: nil)
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func stationRow(label: String, station: TFLStopPoint, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                Text(label).foregroundColor(.primary)
                Spacer()
                if station.naptanId.isEmpty {
                    Text("Choose").foregroundColor(.secondary)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(station.displayName)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        if !station.lineDisplayText.isEmpty {
                            Text(station.lineDisplayText)
                                .font(.system(size: 11))
                                .foregroundColor(Color(.tertiaryLabel))
                                .lineLimit(1)
                        }
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .foregroundColor(.primary)
    }

    private func timePicker(label: String, time: Binding<Date>) -> some View {
        DatePicker(label, selection: time, displayedComponents: .hourAndMinute)
            .tint(.black)
    }

    private func walkPicker(label: String, minutes: Binding<Int>) -> some View {
        Picker(label, selection: minutes) {
            ForEach(walkOptions, id: \.self) { m in
                Text("\(m) min").tag(m)
            }
        }
    }

    // MARK: - Prefill / Save

    private func prefill() {
        guard let s = appState.settings else { return }
        homeStation       = TFLStopPoint(naptanId: s.homeStationId,   commonName: s.homeStationName,   lines: s.homeStationLines)
        homeWalkMinutes   = max(1, s.walkingMinutesToStation)
        officeStation     = TFLStopPoint(naptanId: s.officeStationId, commonName: s.officeStationName, lines: s.officeStationLines)
        officeWalkMinutes = max(1, s.walkingMinutesToOffice)
        arrivalTime       = s.arrivalTime
        notificationTime  = s.notificationTime
        let days = Set(s.officeDays)
        monday    = days.contains(.monday)
        tuesday   = days.contains(.tuesday)
        wednesday = days.contains(.wednesday)
        thursday  = days.contains(.thursday)
        friday    = days.contains(.friday)
        outboundArrivalTime      = s.outboundArrivalTime
        outboundNotificationTime = s.outboundNotificationTime
        outboundWalkMinutes      = max(1, s.outboundWalkingTimeFromStation)
        if s.outboundDestinationType == .otherPlace {
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
        s.notificationTime        = notificationTime
        var days: [Weekday] = []
        if monday    { days.append(.monday) }
        if tuesday   { days.append(.tuesday) }
        if wednesday { days.append(.wednesday) }
        if thursday  { days.append(.thursday) }
        if friday    { days.append(.friday) }
        s.officeDays = days
        if s.outboundEnabled {
            s.outboundArrivalTime      = outboundArrivalTime
            s.outboundNotificationTime = outboundNotificationTime
            s.outboundNotificationDays = days
            if s.outboundDestinationType == .otherPlace {
                s.outboundWalkingTimeFromStation  = outboundWalkMinutes
                s.outboundDestinationStationId    = outboundDestStation.naptanId
                s.outboundDestinationStationName  = outboundDestStation.commonName
                s.outboundDestinationStationLines = outboundDestStation.lines
            }
        }
        appState.updateSettings(s)
        viewModel.updateSettings(s)
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
