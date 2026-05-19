import SwiftUI

#if canImport(GoogleMaps)
import GoogleMaps
import UIKit
#endif

struct CrisisMapView: View {
    let incidents: [Incident]
    let signals: [Signal]
    let routes: [RouteOption]
    let blockedSegments: [BlockedSegment]

    var body: some View {
        #if canImport(GoogleMaps)
        GoogleCrisisMapView(
            incidents: incidents,
            signals: signals,
            routes: routes,
            blockedSegments: blockedSegments
        )
        #else
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(AppTheme.blue)
            Text("Google Maps SDK is not linked")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text("Add the Google Maps iOS Swift package and GOOGLE_MAPS_IOS_API_KEY to render the live map.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.surface)
        #endif
    }
}

#if canImport(GoogleMaps)
struct GoogleCrisisMapView: UIViewRepresentable {
    let incidents: [Incident]
    let signals: [Signal]
    let routes: [RouteOption]
    let blockedSegments: [BlockedSegment]

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: 31.5204, longitude: 74.3587, zoom: 11)
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.mapStyle = try? GMSMapStyle(jsonString: Self.lightBlueStyle)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()

        for route in routes where route.polyline?.isEmpty == false {
            guard let encoded = route.polyline, let path = GMSPath(fromEncodedPath: encoded) else { continue }
            let line = GMSPolyline(path: path)
            line.strokeColor = route.status == "recommended" ? UIColor(AppTheme.blue) : UIColor(AppTheme.sky)
            line.strokeWidth = route.status == "recommended" ? 5 : 3
            line.map = mapView
        }

        for segment in blockedSegments {
            let path = GMSMutablePath()
            path.add(CLLocationCoordinate2D(latitude: segment.startLat, longitude: segment.startLng))
            path.add(CLLocationCoordinate2D(latitude: segment.endLat, longitude: segment.endLng))
            let line = GMSPolyline(path: path)
            line.strokeColor = UIColor(AppTheme.danger)
            line.strokeWidth = 6
            line.map = mapView
        }

        for signal in signals {
            guard let lat = signal.latitude, let lng = signal.longitude else { continue }
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lng))
            marker.title = signal.category?.capitalized ?? "Signal"
            marker.snippet = signal.status.capitalized
            marker.icon = GMSMarker.markerImage(with: UIColor(AppTheme.sky))
            marker.map = mapView
        }

        for incident in incidents {
            guard let lat = incident.centroidLat, let lng = incident.centroidLng else { continue }
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lng))
            marker.title = incident.title
            marker.snippet = "Severity \(incident.severity) • \(incident.status)"
            marker.icon = GMSMarker.markerImage(with: UIColor(AppTheme.severityColor(incident.severity)))
            marker.zIndex = Int32(incident.severity + 10)
            marker.map = mapView
        }

        if let focus = incidents.first(where: { $0.centroidLat != nil && $0.centroidLng != nil }) {
            mapView.animate(to: GMSCameraPosition.camera(
                withLatitude: focus.centroidLat ?? 31.5204,
                longitude: focus.centroidLng ?? 74.3587,
                zoom: 12
            ))
        } else if let signal = signals.first(where: { $0.latitude != nil && $0.longitude != nil }) {
            mapView.animate(to: GMSCameraPosition.camera(
                withLatitude: signal.latitude ?? 31.5204,
                longitude: signal.longitude ?? 74.3587,
                zoom: 12
            ))
        }
    }

    private static let lightBlueStyle = """
    [
      {"featureType":"poi","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"geometry","stylers":[{"color":"#DCEBFF"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#BFDFFF"}]},
      {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#F6FAFF"}]},
      {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#335C8C"}]}
    ]
    """
}
#endif
