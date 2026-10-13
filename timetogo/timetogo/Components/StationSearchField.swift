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
        FormField(label: label, action: { showModal = true }) {
            if selectedStation.naptanId.isEmpty {
                FormFieldValue(text: "Choose", isPlaceholder: true)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    FormFieldValue(text: selectedStation.displayName, isPlaceholder: false)
                    if !selectedStation.lineDisplayText.isEmpty {
                        Text(selectedStation.lineDisplayText)
                            .typography(.footnote)
                            .foregroundColor(.grey30)
                            .lineLimit(1)
                    }
                }
            }
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

    var body: some View {
        NavigationView {
            Group {
                if store.isSearchingStations {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !searchText.isEmpty && store.stationSearchResults.isEmpty {
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
            // Local search over the bundled list: instant, so no debounce needed.
            .onChange(of: searchText) { _, newValue in
                store.searchStations(query: newValue)
            }
            .onAppear {
                store.searchStations(query: searchText)
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
