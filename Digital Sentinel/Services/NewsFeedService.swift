//
//  NewsFeedService.swift
//  Digital Sentinel
//
//  Fetches and parses RSS/Atom news feeds
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum NewsFeedService {
    static let sources: [NewsFeedSource] = [
        NewsFeedSource(name: "BBC World", url: URL(string: "https://feeds.bbci.co.uk/news/world/rss.xml")!),
        NewsFeedSource(name: "NPR News", url: URL(string: "https://feeds.npr.org/1001/rss.xml")!),
        NewsFeedSource(name: "Guardian World", url: URL(string: "https://www.theguardian.com/world/rss")!),
        NewsFeedSource(name: "Reuters World", url: URL(string: "https://news.google.com/rss/search?q=site:reuters.com+world&hl=en-US&gl=US&ceid=US:en")!),
        NewsFeedSource(name: "Al Jazeera", url: URL(string: "https://www.aljazeera.com/xml/rss/all.xml")!),
    ]

    static func fetchAll() async -> (items: [NewsItem], errors: [String]) {
        var collected: [NewsItem] = []
        var errors: [String] = []

        await withTaskGroup(of: Result<[NewsItem], Error>.self) { group in
            for source in sources {
                group.addTask {
                    do {
                        let items = try await fetch(source: source)
                        return .success(items)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            for await result in group {
                switch result {
                case .success(let items):
                    collected.append(contentsOf: items)
                case .failure(let error):
                    errors.append(error.localizedDescription)
                }
            }
        }

        let sorted = collected.sorted {
            ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast)
        }

        return (items: Array(sorted.prefix(200)), errors: errors)
    }

    private static func fetch(source: NewsFeedSource) async throws -> [NewsItem] {
        var request = URLRequest(url: source.url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "NewsFeedService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad response from \(source.name)"])
        }

        let parser = RSSParser(source: source.name)
        return parser.parse(data: data)
    }
}

private final class RSSParser: NSObject, XMLParserDelegate {
    private let source: String
    private var items: [NewsItem] = []

    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDate: String = ""
    private var currentDescription: String = ""
    private var inItem = false
    private var inEntry = false

    init(source: String) {
        self.source = source
    }

    func parse(data: Data) -> [NewsItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName.lowercased()

        if currentElement == "item" {
            inItem = true
            resetCurrent()
        }

        if currentElement == "entry" {
            inEntry = true
            resetCurrent()
        }

        if inEntry && currentElement == "link" {
            if let href = attributeDict["href"], currentLink.isEmpty {
                currentLink = href
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem || inEntry else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed + " "
        case "link":
            if currentLink.isEmpty {
                currentLink += trimmed
            }
        case "pubdate", "updated", "dc:date":
            currentDate += trimmed + " "
        case "description", "summary", "content:encoded":
            currentDescription += trimmed + " "
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard inItem || inEntry else { return }
        if let cdata = String(data: CDATABlock, encoding: .utf8) {
            currentDescription += cdata + " "
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let lower = elementName.lowercased()
        if lower == "item" || lower == "entry" {
            let title = currentTitle.cleaned
            if !title.isEmpty {
                let linkUrl = URL(string: currentLink.cleaned)
                let publishedAt = RSSDateParser.parse(currentDate.cleaned)
                let summary = currentDescription.cleaned.stripHTML().decodingHTMLEntities()
                let item = NewsItem(
                    title: title,
                    link: linkUrl,
                    publishedAt: publishedAt,
                    source: source,
                    summary: summary.isEmpty ? nil : summary
                )
                items.append(item)
            }

            inItem = false
            inEntry = false
            resetCurrent()
        }
    }

    private func resetCurrent() {
        currentTitle = ""
        currentLink = ""
        currentDate = ""
        currentDescription = ""
    }
}

private enum RSSDateParser {
    private static let formatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssXXX"
        ]
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }
    }()

    static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }
}

private extension String {
    var cleaned: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func stripHTML() -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
            return self
        }
        let range = NSRange(location: 0, length: utf16.count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
    }

    func decodingHTMLEntities() -> String {
        guard let data = data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            return attributed.string
        }
        return self
    }
}
