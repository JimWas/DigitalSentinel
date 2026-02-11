//
//  PizzIntService.swift
//  Digital Sentinel
//
//  Fetches Pentagon Pizza Index data from PizzINT (public)
//

import Foundation

enum PizzIntService {
    static func fetchStatus() async throws -> PizzIntStatus {
        let url = URL(string: "https://www.pizzint.watch/api/dashboard-data")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "PizzIntService", code: 1, userInfo: [NSLocalizedDescriptionKey: "PizzINT error"])
        }

        let api = try JSONDecoder().decode(PizzIntApiResponse.self, from: data)
        if !api.success { throw NSError(domain: "PizzIntService", code: 1, userInfo: [NSLocalizedDescriptionKey: "PizzINT invalid response"]) }

        let locations: [PizzIntLocation] = api.data.map { loc in
            let coords = extractCoordinates(address: loc.address)
            return PizzIntLocation(
                id: loc.place_id,
                name: loc.name,
                address: loc.address,
                currentPopularity: loc.current_popularity,
                percentageOfUsual: loc.percentage_of_usual,
                isSpike: loc.is_spike,
                spikeMagnitude: loc.spike_magnitude,
                dataSource: loc.data_source,
                recordedAt: ISO8601DateFormatter().date(from: loc.recorded_at) ?? Date(),
                dataFreshness: loc.data_freshness,
                isClosedNow: loc.is_closed_now ?? false,
                latitude: coords.lat,
                longitude: coords.lng
            )
        }

        let openLocations = locations.filter { !$0.isClosedNow }
        let locationsWithUsual = locations.filter { ($0.percentageOfUsual ?? 0) > 0 }

        let aggregateActivity: Int
        if !locationsWithUsual.isEmpty {
            let avg = locationsWithUsual.reduce(0.0) { sum, loc in
                sum + min(loc.percentageOfUsual ?? 0, 100)
            } / Double(locationsWithUsual.count)
            aggregateActivity = Int(round(avg))
        } else if !openLocations.isEmpty {
            let avg = openLocations.reduce(0.0) { sum, loc in
                sum + Double(loc.currentPopularity)
            } / Double(openLocations.count)
            aggregateActivity = Int(round(avg))
        } else {
            aggregateActivity = 0
        }

        let activeSpikes = locations.filter { $0.isSpike }.count
        let freshness = locations.contains { $0.dataFreshness == "fresh" } ? "fresh" : "stale"
        let defcon = calculateDefcon(aggregateActivity: aggregateActivity, activeSpikes: activeSpikes)

        let latestUpdate = locations.reduce(Date(timeIntervalSince1970: 0)) { latest, loc in
            max(latest, loc.recordedAt)
        }

        return PizzIntStatus(
            defconLevel: defcon.level,
            defconLabel: defcon.label,
            aggregateActivity: aggregateActivity,
            activeSpikes: activeSpikes,
            locationsMonitored: locations.count,
            locationsOpen: openLocations.count,
            lastUpdate: latestUpdate,
            dataFreshness: freshness,
            locations: locations
        )
    }

    static func fetchTensions() async throws -> [GdeltTensionPair] {
        let pairs = "usa_russia,russia_ukraine,usa_china,china_taiwan,usa_iran,usa_venezuela"
        let endDate = dateString(daysBack: 0)
        let startDate = dateString(daysBack: 90)

        var components = URLComponents(string: "https://www.pizzint.watch/api/gdelt/batch")
        components?.queryItems = [
            URLQueryItem(name: "pairs", value: pairs),
            URLQueryItem(name: "method", value: "gpr"),
            URLQueryItem(name: "dateStart", value: startDate),
            URLQueryItem(name: "dateEnd", value: endDate)
        ]

        guard let url = components?.url else {
            throw NSError(domain: "PizzIntService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Bad GDELT URL"])
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "PizzIntService", code: 2, userInfo: [NSLocalizedDescriptionKey: "GDELT error"])
        }

        let api = try JSONDecoder().decode([String: [GdeltPoint]].self, from: data)
        return buildTensionPairs(from: api)
    }

    private static func buildTensionPairs(from api: [String: [GdeltPoint]]) -> [GdeltTensionPair] {
        let pairs: [(id: String, label: String)] = [
            ("usa_russia", "USA ↔ Russia"),
            ("russia_ukraine", "Russia ↔ Ukraine"),
            ("usa_china", "USA ↔ China"),
            ("china_taiwan", "China ↔ Taiwan"),
            ("usa_iran", "USA ↔ Iran"),
            ("usa_venezuela", "USA ↔ Venezuela")
        ]

        return pairs.map { pair in
            let pairData = api[pair.id] ?? []
            let recent = Array(pairData.suffix(7))
            let older = Array(pairData.suffix(14).prefix(7))

            let recentAvg = recent.isEmpty ? 0 : recent.map { $0.v }.reduce(0, +) / Double(recent.count)
            let olderAvg = older.isEmpty ? recentAvg : older.map { $0.v }.reduce(0, +) / Double(older.count)

            let changePercent = olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg) * 100 : 0
            let trend: String
            if changePercent > 5 {
                trend = "rising"
            } else if changePercent < -5 {
                trend = "falling"
            } else {
                trend = "stable"
            }

            return GdeltTensionPair(
                id: pair.id,
                label: pair.label,
                score: Double(round(recentAvg * 10) / 10),
                trend: trend,
                changePercent: Double(round(changePercent * 10) / 10)
            )
        }
    }

    private static func dateString(daysBack: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    private static func extractCoordinates(address: String) -> (lat: Double?, lng: Double?) {
        let regex = try? NSRegularExpression(pattern: "@(-?\\d+\\.?\\d*),(-?\\d+\\.?\\d*)")
        let range = NSRange(location: 0, length: address.utf16.count)
        if let match = regex?.firstMatch(in: address, range: range), match.numberOfRanges == 3,
           let latRange = Range(match.range(at: 1), in: address),
           let lngRange = Range(match.range(at: 2), in: address) {
            return (Double(address[latRange]), Double(address[lngRange]))
        }
        return (nil, nil)
    }

    private static func calculateDefcon(aggregateActivity: Int, activeSpikes: Int) -> (level: Int, label: String) {
        var adjusted = aggregateActivity + (activeSpikes * 10)
        if adjusted > 100 { adjusted = 100 }

        let thresholds: [(level: Int, min: Int, label: String)] = [
            (1, 85, "COCKED PISTOL • MAXIMUM READINESS"),
            (2, 70, "FAST PACE • ARMED FORCES READY"),
            (3, 50, "ROUND HOUSE • INCREASE FORCE READINESS"),
            (4, 25, "DOUBLE TAKE • INCREASED INTELLIGENCE WATCH"),
            (5, 0, "FADE OUT • LOWEST READINESS")
        ]

        for threshold in thresholds {
            if adjusted >= threshold.min { return (threshold.level, threshold.label) }
        }

        return (5, "FADE OUT • LOWEST READINESS")
    }
}

private struct PizzIntApiResponse: Decodable {
    let success: Bool
    let data: [PizzIntApiLocation]
}

private struct PizzIntApiLocation: Decodable {
    let place_id: String
    let name: String
    let address: String
    let current_popularity: Int
    let percentage_of_usual: Double?
    let is_spike: Bool
    let spike_magnitude: Double?
    let data_source: String
    let recorded_at: String
    let data_freshness: String
    let is_closed_now: Bool?
}

private struct GdeltPoint: Decodable {
    let t: Double
    let v: Double
}
