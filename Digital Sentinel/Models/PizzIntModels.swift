//
//  PizzIntModels.swift
//  Digital Sentinel
//
//  Pentagon Pizza Index models
//

import Foundation

struct PizzIntLocation: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let currentPopularity: Int
    let percentageOfUsual: Double?
    let isSpike: Bool
    let spikeMagnitude: Double?
    let dataSource: String
    let recordedAt: Date
    let dataFreshness: String
    let isClosedNow: Bool
    let latitude: Double?
    let longitude: Double?
}

struct PizzIntStatus {
    let defconLevel: Int
    let defconLabel: String
    let aggregateActivity: Int
    let activeSpikes: Int
    let locationsMonitored: Int
    let locationsOpen: Int
    let lastUpdate: Date
    let dataFreshness: String
    let locations: [PizzIntLocation]
}

struct GdeltTensionPair: Identifiable {
    let id: String
    let label: String
    let score: Double
    let trend: String
    let changePercent: Double
}

enum PizzIntLoadState: Equatable {
    case idle
    case loading
    case failed(String)
}
