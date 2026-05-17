import SwiftUI

// MARK: - Station Search Field

/// Tappable input field for station selection.
/// Empty state shows "Choose"; filled state shows station name + line subtitle (2-line layout).
struct StationSearchField: View {
    var label: String
    @Binding var selectedStation: TFLStopPoint
    @EnvironmentObject var store: TFLDataStore

    @State private var showModal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .labelStyle()
                .foregroundColor(.black)

            Button {
                showModal = true
            } label: {
                HStack {
                    if selectedStation.naptanId.isEmpty {
                        Text("Choose")
                            .h4Style()
                            .foregroundColor(Color.grey50)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedStation.displayName)
                                .h4Style()
                                .foregroundColor(.black)
                            if !selectedStation.lineDisplayText.isEmpty {
                                Text(selectedStation.lineDisplayText.uppercased())
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.grey30)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: 56)
                .frame(maxWidth: .infinity)
                .background(Color.grey10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.grey30, lineWidth: 1)
                )
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showModal) {
            StationSearchModalView(
                title: label,
                selectedStation: $selectedStation,
                onDismiss: { showModal = false }
            )
            .environmentObject(store)
            .preferredColorScheme(.light)
        }
    }
}

// MARK: - Station Search Modal

struct StationSearchModalView: View {
    var title: String
    @Binding var selectedStation: TFLStopPoint
    var onDismiss: () -> Void

    @EnvironmentObject var store: TFLDataStore
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            Group {
                if store.isSearchingStations {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.count >= 2 && store.stationSearchResults.isEmpty {
                    Text("No stations found")
                        .foregroundColor(Color.grey30)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.stationSearchResults) { station in
                            Button {
                                selectedStation = station
                                onDismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(station.displayName)
                                            .labelStyle()
                                            .foregroundColor(.black)
                                        if !station.lineDisplayText.isEmpty {
                                            Text(station.lineDisplayText)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Color.grey30)
                                        }
                                    }
                                    Spacer()
                                    if station == selectedStation {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search stations"
            )
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    store.searchStations(query: newValue)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(.black)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .preferredColorScheme(.light)
        }
        .navigationViewStyle(.stack)
        .onDisappear {
            searchTask?.cancel()
            store.clearStationSearch()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var station = TFLStopPoint.placeholder

        var body: some View {
            VStack(spacing: 24) {
                StationSearchField(label: "Your station", selectedStation: $station)
                StationSearchField(
                    label: "Your station",
                    selectedStation: .constant(TFLStopPoint(
                        naptanId: "940GZZLUWSP",
                        commonName: "West Hampstead Underground Station",
                        lines: [TFLLineRef(id: "jubilee", name: "Jubilee")]
                    ))
                )
                StationSearchField(
                    label: "Your station",
                    selectedStation: .constant(TFLStopPoint(
                        naptanId: "940GZZLUBST",
                        commonName: "Baker Street Underground Station",
                        lines: [
                            TFLLineRef(id: "bakerloo",         name: "Bakerloo"),
                            TFLLineRef(id: "circle",           name: "Circle"),
                            TFLLineRef(id: "hammersmith-city", name: "Hammersmith & City"),
                            TFLLineRef(id: "jubilee",          name: "Jubilee"),
                            TFLLineRef(id: "metropolitan",     name: "Metropolitan")
                        ]
                    ))
                )
            }
            .padding(24)
            .environmentObject(TFLDataStore(service: MockTFLService()))
        }
    }
    return PreviewWrapper()
}
