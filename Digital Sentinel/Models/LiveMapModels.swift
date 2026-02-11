//
//  LiveMapModels.swift
//  Digital Sentinel
//
//  Live map overlay models
//

import Foundation

enum LiveMapKind {
    case hotspot
    case conflict
    case base
}

struct LiveMapPoint: Identifiable, Hashable {
    let id: String
    let name: String
    let coordinate: GeoCoordinate
    let weight: Double
    let kind: LiveMapKind

    init(id: String, name: String, coordinate: GeoCoordinate, weight: Double = 1, kind: LiveMapKind) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.weight = weight
        self.kind = kind
    }
}
