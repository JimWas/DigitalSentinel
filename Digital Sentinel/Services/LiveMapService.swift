//
//  LiveMapService.swift
//  Digital Sentinel
//
//  Fetches live map overlays from free/public sources
//

import Foundation
import MapKit

enum LiveMapService {
    private static let gdeltBase = "https://api.gdeltproject.org/api/v2/geo/geo"
    private static let overpassBase = "https://overpass-api.de/api/interpreter"

    static func fetchHotspots() async throws -> [LiveMapPoint] {
        let query = "(attack OR strike OR bombing OR missile OR insurgent OR terrorist)"
        return try await fetchGdeltPoints(query: query, kind: .hotspot, fallbackName: "Hotspot")
    }

    static func fetchConflictZones() async throws -> [LiveMapPoint] {
        let query = "(conflict OR war OR clashes OR fighting OR invasion)"
        return try await fetchGdeltPoints(query: query, kind: .conflict, fallbackName: "Conflict")
    }

    static func fetchMilitaryBases(region: MKCoordinateRegion) async throws -> [LiveMapPoint] {
        let bbox = bboxString(for: region)
        let query = "[out:json][timeout:25];(nwr[\"military\"](\(bbox));nwr[\"amenity\"=\"military\"](\(bbox)););out center 200;"

        var request = URLRequest(url: URL(string: overpassBase)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "LiveMapService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Overpass error"])
        }

        let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
        return decoded.elements.compactMap { element in
            let lat = element.lat ?? element.center?.lat
            let lon = element.lon ?? element.center?.lon
            guard let latValue = lat, let lonValue = lon else { return nil }
            let name = element.tags?["name"] ?? "Military Site"
            let id = "base-\(element.id)"
            return LiveMapPoint(
                id: id,
                name: name,
                coordinate: GeoCoordinate(latitude: latValue, longitude: lonValue),
                weight: 1,
                kind: .base
            )
        }
    }

    private static func fetchGdeltPoints(query: String, kind: LiveMapKind, fallbackName: String) async throws -> [LiveMapPoint] {
        var components = URLComponents(string: gdeltBase)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "mode", value: "point"),
            URLQueryItem(name: "format", value: "geojson")
        ]

        guard let url = components?.url else {
            throw NSError(domain: "LiveMapService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad GDELT URL"])
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "LiveMapService", code: 1, userInfo: [NSLocalizedDescriptionKey: "GDELT error"])
        }

        let decoded = try JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data)
        return decoded.features.compactMap { feature in
            guard feature.geometry.type.lowercased() == "point",
                  feature.geometry.coordinates.count >= 2 else { return nil }
            let lon = feature.geometry.coordinates[0]
            let lat = feature.geometry.coordinates[1]
            let name = feature.properties["name"]?.stringValue ?? feature.properties["title"]?.stringValue ?? fallbackName
            let weight = feature.properties["count"]?.doubleValue ?? 1
            let id = feature.properties["id"]?.stringValue ?? "\(kind)-\(lat)-\(lon)"
            return LiveMapPoint(
                id: id,
                name: name,
                coordinate: GeoCoordinate(latitude: lat, longitude: lon),
                weight: weight,
                kind: kind
            )
        }
    }

    private static func bboxString(for region: MKCoordinateRegion) -> String {
        let lat = region.center.latitude
        let lon = region.center.longitude
        let latDelta = region.span.latitudeDelta / 2
        let lonDelta = region.span.longitudeDelta / 2

        let south = max(-85, lat - latDelta)
        let north = min(85, lat + latDelta)
        let west = max(-180, lon - lonDelta)
        let east = min(180, lon + lonDelta)

        return "\(south),\(west),\(north),\(east)"
    }
}

private struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
    let properties: [String: JSONValue]
}

private struct GeoJSONGeometry: Decodable {
    let type: String
    let coordinates: [Double]
}

private struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

private struct OverpassElement: Decodable {
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: OverpassCenter?
    let tags: [String: String]?
}

private struct OverpassCenter: Decodable {
    let lat: Double
    let lon: Double
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        if case .number(let value) = self { return String(value) }
        return nil
    }

    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        if case .string(let value) = self { return Double(value) }
        return nil
    }
}
