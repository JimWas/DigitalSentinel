//
//  NewsModels.swift
//  Digital Sentinel
//
//  Live news feed models
//

import Foundation

struct NewsItem: Identifiable, Hashable {
    let id: String
    let title: String
    let link: URL?
    let publishedAt: Date?
    let source: String
    let summary: String?

    init(title: String, link: URL?, publishedAt: Date?, source: String, summary: String?) {
        let baseId = link?.absoluteString ?? "\(source)-\(title)-\(publishedAt?.timeIntervalSince1970 ?? 0)"
        self.id = baseId
        self.title = title
        self.link = link
        self.publishedAt = publishedAt
        self.source = source
        self.summary = summary
    }
}

enum NewsStatus: Equatable {
    case idle
    case loading
    case failed(String)
}

struct NewsFeedSource: Hashable {
    let name: String
    let url: URL
}
