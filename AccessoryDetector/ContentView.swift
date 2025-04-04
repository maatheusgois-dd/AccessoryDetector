//
//  ContentView.swift
//  AccessoryDetector
//
//  Created by Matheus Gois on 03/04/25.
//

import SwiftUI
import MapKit
import CoreLocation
import ExternalAccessory

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var locationStatus: String = "Locating..."
    @Published var isSimulated: Bool = false
    @Published var isFromAccessory: Bool = false
    @Published var accessoriesInfo: String = ""

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        loadAccessories()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        region.center = location.coordinate
        locationStatus = "Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)"

        if #available(iOS 15.0, *) {
            if let info = location.sourceInformation {
                isSimulated = info.isSimulatedBySoftware
                isFromAccessory = info.isProducedByAccessory
            } else {
                isSimulated = false
                isFromAccessory = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatus = "Error: \(error.localizedDescription)"
    }

    func loadAccessories() {
        let connectedAccessories = EAAccessoryManager.shared().connectedAccessories
        if connectedAccessories.isEmpty {
            accessoriesInfo = "No connected accessories"
        } else {
            accessoriesInfo = connectedAccessories.map {
                "• \($0.name) by \($0.manufacturer)"
            }.joined(separator: "\n")
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = LocationViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true)
                .frame(height: 300)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationStatus)
                    .font(.headline)

                if viewModel.isSimulated {
                    Text("⚠️ Location is simulated by software")
                        .foregroundColor(.red)
                }

                if viewModel.isFromAccessory {
                    Text("📡 Location is from an external accessory")
                        .foregroundColor(.blue)
                }
            }

            Divider()

            VStack(alignment: .center) {
                Text("Connected Accessories:")
                    .font(.headline)
                Text(viewModel.accessoriesInfo)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Button("Refresh Accessories") {
                viewModel.loadAccessories()
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
