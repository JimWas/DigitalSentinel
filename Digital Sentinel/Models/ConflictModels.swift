//
//  ConflictModels.swift
//  Digital Sentinel
//
//  Global Conflict Monitoring Data Models
//

import Foundation
import SwiftUI
import Combine
import MapKit

// MARK: - Threat Level
enum ThreatLevel: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var color: Color {
        switch self {
        case .critical: return Color(red: 1.0, green: 0.2, blue: 0.2)
        case .high: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .medium: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .low: return Color(red: 0.0, green: 0.8, blue: 0.4)
        }
    }

    var pulseIntensity: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.7
        case .medium: return 0.4
        case .low: return 0.2
        }
    }
}

// MARK: - Conflict Type
enum ConflictType: String, Codable, CaseIterable {
    case battles = "Battles"
    case violenceAgainstCivilians = "Violence against civilians"
    case protests = "Protests"
    case riots = "Riots"
    case strategicDevelopments = "Strategic developments"
    case cyberWarfare = "Cyber Warfare"

    var icon: String {
        switch self {
        case .battles: return "burst.fill"
        case .violenceAgainstCivilians: return "exclamationmark.triangle.fill"
        case .protests: return "figure.walk"
        case .riots: return "flame.fill"
        case .strategicDevelopments: return "arrow.triangle.branch"
        case .cyberWarfare: return "network"
        }
    }
}

// MARK: - Conflict Status
enum ConflictStatus: String, Codable {
    case active = "Active"
    case escalating = "Escalating"
    case deescalating = "De-escalating"
    case monitoring = "Monitoring"
    case ceasefire = "Ceasefire"
}

// MARK: - Connection Line Type
enum ConnectionLineType: String, CaseIterable {
    case proxyWar = "Proxy War"
    case armsFlow = "Arms Flow"
    case alliance = "Alliance"
    case spillover = "Spillover"
    case cyberLink = "Cyber Link"

    var color: Color {
        switch self {
        case .proxyWar: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .armsFlow: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .alliance: return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .spillover: return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .cyberLink: return Color(red: 0.0, green: 1.0, blue: 0.6)
        }
    }

    var dashPattern: [CGFloat] {
        switch self {
        case .proxyWar: return [5, 3]
        case .armsFlow: return [8, 4]
        case .alliance: return []
        case .spillover: return [3, 3]
        case .cyberLink: return [2, 2]
        }
    }
}

// MARK: - Geographic Coordinates
struct GeoCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    // Convert to normalized screen position (0-1 range)
    var normalizedPosition: CGPoint {
        let x = (longitude + 180) / 360
        let y = (90 - latitude) / 180
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Conflict Event
struct ConflictEvent: Identifiable, Codable {
    let id: UUID
    let date: String
    let location: String
    let country: String
    let type: String
    let fatalities: Int
    let parties: String
    let description: String

    // Additional computed properties
    var conflictType: ConflictType {
        ConflictType(rawValue: type) ?? .battles
    }

    init(id: UUID = UUID(), date: String, location: String, country: String, type: String, fatalities: Int, parties: String, description: String) {
        self.id = id
        self.date = date
        self.location = location
        self.country = country
        self.type = type
        self.fatalities = fatalities
        self.parties = parties
        self.description = description
    }
}

// MARK: - Major Conflict (Aggregated)
struct MajorConflict: Identifiable {
    let id: UUID
    let name: String
    let type: ConflictType
    let region: String
    let threatLevel: ThreatLevel
    let status: ConflictStatus
    let casualties: Int
    let displaced: Double // in millions
    let startDate: String
    let parties: [String]
    let description: String
    let coordinate: GeoCoordinate
    let recentEvents: [ConflictEvent]

    // Analytics data
    var escalationRisk: Int // 0-100
    var humanitarianCrisis: Int // 0-100
    var geopoliticalImpact: Int // 0-100
    var stabilityIndex: Int // 0-10
}

// MARK: - Global Statistics
struct GlobalStatistics {
    var activeConflicts: Int
    var criticalCount: Int
    var escalatingCount: Int
    var totalDisplaced: Double // in millions
    var activeZones: Int

    static var sample: GlobalStatistics {
        GlobalStatistics(
            activeConflicts: 20,
            criticalCount: 3,
            escalatingCount: 7,
            totalDisplaced: 54.7,
            activeZones: 20
        )
    }
}

// MARK: - Network Node (for visualization)
struct NetworkNode: Identifiable {
    let id: UUID
    let name: String
    let type: NodeType
    let connections: [UUID]
    var position: CGPoint

    enum NodeType {
        case stateActor
        case nonStateActor
        case aptGroup
        case region

        var color: Color {
            switch self {
            case .stateActor: return Color(red: 1.0, green: 0.3, blue: 0.3)
            case .nonStateActor: return Color(red: 1.0, green: 0.6, blue: 0.0)
            case .aptGroup: return Color(red: 0.0, green: 1.0, blue: 0.6)
            case .region: return Color(red: 0.5, green: 0.5, blue: 0.5)
            }
        }
    }
}

// MARK: - Sample Data Generator
class ConflictDataManager: ObservableObject {
    @Published var conflicts: [MajorConflict] = []
    @Published var events: [ConflictEvent] = []
    @Published var statistics: GlobalStatistics = .sample
    @Published var selectedConflict: MajorConflict?
    @Published var searchText: String = ""
    @Published var selectedFilter: ThreatLevel?
    @Published var newsItems: [NewsItem] = []
    @Published var newsStatus: NewsStatus = .idle
    @Published var lastNewsUpdate: Date?
    @Published var liveHotspots: [LiveMapPoint] = []
    @Published var liveConflicts: [LiveMapPoint] = []
    @Published var liveBases: [LiveMapPoint] = []
    @Published var pizzIntStatus: PizzIntStatus?
    @Published var pizzIntTensions: [GdeltTensionPair] = []
    @Published var pizzIntState: PizzIntLoadState = .idle

    private var newsTimer: Timer?
    private var pizzIntTimer: Timer?
    private var mapFetchWorkItem: DispatchWorkItem?
    private var lastMapFetch: Date?
    private var lastBasesKey: String?
    private var lastBasesFetch: Date?

    init() {
        loadSampleData()
        refreshNews()
        scheduleNewsRefresh()
        refreshPizzInt()
        schedulePizzIntRefresh()
    }

    deinit {
        newsTimer?.invalidate()
        pizzIntTimer?.invalidate()
    }

    func loadSampleData() {
        // Load events from JSON if available, otherwise use sample data
        conflicts = Self.sampleConflicts
        events = Self.sampleEvents
    }

    func refreshNews() {
        newsStatus = .loading

        Task {
            let result = await NewsFeedService.fetchAll()
            await MainActor.run {
                if result.items.isEmpty {
                    newsStatus = .failed("No live feeds available")
                } else {
                    newsStatus = .idle
                }
                newsItems = result.items
                lastNewsUpdate = Date()
            }
        }
    }

    private func scheduleNewsRefresh() {
        newsTimer?.invalidate()
        newsTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.refreshNews()
        }
    }

    func refreshPizzInt() {
        pizzIntState = .loading

        Task {
            async let status = PizzIntService.fetchStatus()
            async let tensions = PizzIntService.fetchTensions()

            do {
                let (statusValue, tensionValues) = try await (status, tensions)
                await MainActor.run {
                    pizzIntStatus = statusValue
                    pizzIntTensions = tensionValues
                    pizzIntState = .idle
                }
            } catch {
                await MainActor.run {
                    pizzIntState = .failed("PizzINT unavailable")
                }
            }
        }
    }

    private func schedulePizzIntRefresh() {
        pizzIntTimer?.invalidate()
        pizzIntTimer = Timer.scheduledTimer(withTimeInterval: 10 * 60, repeats: true) { [weak self] _ in
            self?.refreshPizzInt()
        }
    }

    func updateMapRegion(_ region: MKCoordinateRegion) {
        mapFetchWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchLiveMapData(region: region)
        }
        mapFetchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
    }

    private func fetchLiveMapData(region: MKCoordinateRegion) {
        let now = Date()
        if let last = lastMapFetch, now.timeIntervalSince(last) < 60 {
            return
        }
        lastMapFetch = now

        Task {
            async let hotspotsResult = LiveMapService.fetchHotspots()
            async let conflictsResult = LiveMapService.fetchConflictZones()

            var baseItems: [LiveMapPoint] = liveBases
            if shouldFetchBases(for: region) {
                let key = regionKey(region)
                let isStale = lastBasesFetch.map { now.timeIntervalSince($0) > 10 * 60 } ?? true
                if key != lastBasesKey || isStale {
                    do {
                        baseItems = try await LiveMapService.fetchMilitaryBases(region: region)
                        lastBasesKey = key
                        lastBasesFetch = now
                    } catch {
                        // Keep previous base data on failure
                    }
                }
            }

            do {
                let hotspotItems = try await hotspotsResult
                let conflictItems = try await conflictsResult
                await MainActor.run {
                    liveHotspots = Array(hotspotItems.prefix(120))
                    liveConflicts = Array(conflictItems.prefix(120))
                    liveBases = Array(baseItems.prefix(150))
                }
            } catch {
                // Keep previous data if fetch fails
            }
        }
    }

    private func shouldFetchBases(for region: MKCoordinateRegion) -> Bool {
        // Overpass timeouts are common when zoomed far out. Only fetch when reasonably zoomed in.
        return region.span.latitudeDelta < 70 && region.span.longitudeDelta < 120
    }

    private func regionKey(_ region: MKCoordinateRegion) -> String {
        let lat = (region.center.latitude * 10).rounded() / 10
        let lon = (region.center.longitude * 10).rounded() / 10
        let latSpan = (region.span.latitudeDelta * 10).rounded() / 10
        let lonSpan = (region.span.longitudeDelta * 10).rounded() / 10
        return "\(lat),\(lon),\(latSpan),\(lonSpan)"
    }

    var filteredConflicts: [MajorConflict] {
        var result = conflicts

        if !searchText.isEmpty {
            result = result.filter { conflict in
                conflict.name.localizedCaseInsensitiveContains(searchText) ||
                conflict.region.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let filter = selectedFilter {
            result = result.filter { $0.threatLevel == filter }
        }

        return result
    }

    static var sampleConflicts: [MajorConflict] {
        [
            MajorConflict(
                id: UUID(),
                name: "Russia-Ukraine War",
                type: .battles,
                region: "Eastern Europe",
                threatLevel: .critical,
                status: .active,
                casualties: 500000,
                displaced: 6.4,
                startDate: "2022-02-24",
                parties: ["Military Forces of Ukraine", "Military Forces of Russia"],
                description: "Full-scale invasion and ongoing war between Russia and Ukraine across multiple fronts.",
                coordinate: GeoCoordinate(latitude: 48.3794, longitude: 31.1656),
                recentEvents: [],
                escalationRisk: 85,
                humanitarianCrisis: 92,
                geopoliticalImpact: 95,
                stabilityIndex: 2
            ),
            MajorConflict(
                id: UUID(),
                name: "Israel-Palestine Conflict",
                type: .battles,
                region: "Middle East",
                threatLevel: .critical,
                status: .escalating,
                casualties: 45000,
                displaced: 1.9,
                startDate: "2023-10-07",
                parties: ["Military Forces of Israel", "Hamas", "Palestinian Civilians"],
                description: "Intense military operations in Gaza following October 2023 attacks.",
                coordinate: GeoCoordinate(latitude: 31.5, longitude: 34.47),
                recentEvents: [],
                escalationRisk: 90,
                humanitarianCrisis: 98,
                geopoliticalImpact: 85,
                stabilityIndex: 1
            ),
            MajorConflict(
                id: UUID(),
                name: "Sudan Civil War",
                type: .battles,
                region: "North Africa",
                threatLevel: .critical,
                status: .escalating,
                casualties: 15000,
                displaced: 7.1,
                startDate: "2023-04-15",
                parties: ["Sudanese Armed Forces", "Rapid Support Forces"],
                description: "Armed conflict between the Sudanese Armed Forces and Rapid Support Forces.",
                coordinate: GeoCoordinate(latitude: 15.5007, longitude: 32.5599),
                recentEvents: [],
                escalationRisk: 80,
                humanitarianCrisis: 95,
                geopoliticalImpact: 65,
                stabilityIndex: 2
            ),
            MajorConflict(
                id: UUID(),
                name: "Myanmar Civil War",
                type: .violenceAgainstCivilians,
                region: "Southeast Asia",
                threatLevel: .high,
                status: .active,
                casualties: 50000,
                displaced: 2.6,
                startDate: "2021-02-01",
                parties: ["Military Forces of Myanmar", "People's Defence Forces", "Ethnic Armed Organizations"],
                description: "Civil war following military coup; widespread resistance and ethnic conflicts.",
                coordinate: GeoCoordinate(latitude: 19.7633, longitude: 96.0785),
                recentEvents: [],
                escalationRisk: 70,
                humanitarianCrisis: 85,
                geopoliticalImpact: 55,
                stabilityIndex: 3
            ),
            MajorConflict(
                id: UUID(),
                name: "Ethiopia Instability",
                type: .battles,
                region: "East Africa",
                threatLevel: .high,
                status: .monitoring,
                casualties: 600000,
                displaced: 4.5,
                startDate: "2020-11-04",
                parties: ["Ethiopian National Defense Force", "Tigray People's Liberation Front", "Fano Militia"],
                description: "Civil unrest and armed clashes in multiple regions despite peace agreement.",
                coordinate: GeoCoordinate(latitude: 9.145, longitude: 40.4897),
                recentEvents: [],
                escalationRisk: 65,
                humanitarianCrisis: 88,
                geopoliticalImpact: 50,
                stabilityIndex: 4
            ),
            MajorConflict(
                id: UUID(),
                name: "Syrian Conflict",
                type: .strategicDevelopments,
                region: "Middle East",
                threatLevel: .medium,
                status: .monitoring,
                casualties: 610000,
                displaced: 6.8,
                startDate: "2011-03-15",
                parties: ["Military Forces of Syria", "Opposition Forces", "Kurdish Forces", "ISIS Remnants"],
                description: "Prolonged civil war with multiple factions; ongoing ceasefire violations.",
                coordinate: GeoCoordinate(latitude: 35.8623, longitude: 37.0),
                recentEvents: [],
                escalationRisk: 55,
                humanitarianCrisis: 82,
                geopoliticalImpact: 70,
                stabilityIndex: 4
            ),
            MajorConflict(
                id: UUID(),
                name: "Yemen Conflict",
                type: .battles,
                region: "Middle East",
                threatLevel: .high,
                status: .active,
                casualties: 377000,
                displaced: 4.5,
                startDate: "2014-09-21",
                parties: ["Yemeni Government Forces", "Houthi Forces", "Saudi-led Coalition"],
                description: "Civil war with regional involvement; severe humanitarian crisis.",
                coordinate: GeoCoordinate(latitude: 15.5527, longitude: 48.5164),
                recentEvents: [],
                escalationRisk: 72,
                humanitarianCrisis: 96,
                geopoliticalImpact: 68,
                stabilityIndex: 2
            ),
            MajorConflict(
                id: UUID(),
                name: "Global Cyber Warfare",
                type: .cyberWarfare,
                region: "Global",
                threatLevel: .high,
                status: .escalating,
                casualties: 0,
                displaced: 0,
                startDate: "2020-01-01",
                parties: ["Multiple State Actors", "APT Groups"],
                description: "State-sponsored cyber attacks targeting critical infrastructure across nations.",
                coordinate: GeoCoordinate(latitude: 38.9072, longitude: -77.0369),
                recentEvents: [],
                escalationRisk: 78,
                humanitarianCrisis: 0,
                geopoliticalImpact: 88,
                stabilityIndex: 5
            ),
            MajorConflict(
                id: UUID(),
                name: "Haiti Crisis",
                type: .riots,
                region: "Caribbean",
                threatLevel: .high,
                status: .escalating,
                casualties: 8000,
                displaced: 0.7,
                startDate: "2021-07-07",
                parties: ["Gang Coalitions", "Police Forces of Haiti", "Civilians"],
                description: "Gang violence and political instability creating humanitarian emergency.",
                coordinate: GeoCoordinate(latitude: 18.9712, longitude: -72.2852),
                recentEvents: [],
                escalationRisk: 75,
                humanitarianCrisis: 80,
                geopoliticalImpact: 35,
                stabilityIndex: 2
            ),
            MajorConflict(
                id: UUID(),
                name: "Taiwan Strait Tensions",
                type: .strategicDevelopments,
                region: "East Asia",
                threatLevel: .medium,
                status: .monitoring,
                casualties: 0,
                displaced: 0,
                startDate: "2022-08-01",
                parties: ["Military Forces of China", "Military Forces of Taiwan", "United States"],
                description: "Increased military exercises; heightened regional tensions.",
                coordinate: GeoCoordinate(latitude: 23.6978, longitude: 120.9605),
                recentEvents: [],
                escalationRisk: 60,
                humanitarianCrisis: 0,
                geopoliticalImpact: 95,
                stabilityIndex: 6
            ),
            MajorConflict(
                id: UUID(),
                name: "DRC Conflict",
                type: .violenceAgainstCivilians,
                region: "Central Africa",
                threatLevel: .high,
                status: .active,
                casualties: 120000,
                displaced: 6.9,
                startDate: "1996-10-24",
                parties: ["DRC Armed Forces", "M23 Rebels", "ADF", "Various Militias"],
                description: "Multiple armed groups operating in eastern DRC; mass displacement.",
                coordinate: GeoCoordinate(latitude: -1.6596, longitude: 29.2207),
                recentEvents: [],
                escalationRisk: 68,
                humanitarianCrisis: 90,
                geopoliticalImpact: 45,
                stabilityIndex: 3
            ),
            MajorConflict(
                id: UUID(),
                name: "Sahel Insurgency",
                type: .battles,
                region: "West Africa",
                threatLevel: .high,
                status: .active,
                casualties: 50000,
                displaced: 3.2,
                startDate: "2012-01-16",
                parties: ["JNIM", "ISIS-Sahel", "National Armed Forces", "Wagner Group"],
                description: "Islamist insurgency across Mali, Burkina Faso, and Niger.",
                coordinate: GeoCoordinate(latitude: 16.7666, longitude: -3.0026),
                recentEvents: [],
                escalationRisk: 72,
                humanitarianCrisis: 78,
                geopoliticalImpact: 55,
                stabilityIndex: 3
            )
        ]
    }

    static var sampleEvents: [ConflictEvent] {
        [
            ConflictEvent(date: "Feb 8, 2026", location: "Donetsk", country: "Ukraine", type: "Battles", fatalities: 12, parties: "Military Forces of Ukraine vs Military Forces of Russia", description: "Artillery exchanges in eastern region."),
            ConflictEvent(date: "Feb 7, 2026", location: "Gaza Strip", country: "Palestine", type: "Battles", fatalities: 45, parties: "Military Forces of Israel vs Hamas", description: "Intense fighting in central Gaza."),
            ConflictEvent(date: "Feb 6, 2026", location: "Khartoum", country: "Sudan", type: "Battles", fatalities: 23, parties: "SAF vs RSF", description: "Heavy fighting in residential areas.")
        ]
    }
}
