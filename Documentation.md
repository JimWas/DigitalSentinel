# Digital Sentinel — Developer Documentation

This document describes the app’s architecture, features, data sources, and key modules so contributors can work effectively.

## Overview
Digital Sentinel is a SwiftUI iOS app inspired by the World Monitor dashboard. It presents a Matrix-style UI with a live map, intelligence panels, and data-driven overlays.

## Key Features
- Matrix-themed UI with scanlines and Nasalization font.
- World Monitor–style dashboard layout (header, map, side panels, ticker).
- Live RSS news feed with in-app browser (SFSafariViewController).
- World Brief panel derived from live headlines.
- Live map overlays for:
  - Intel hotspots
  - Conflict zones
  - Military bases
- Pentagon Pizza Index (PizzINT) DEFCON indicator + detail panel.
- Launch screen storyboard and explicit orientation support.

## Core Screens
### Dashboard
File: `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Views/WorldMonitorDashboardView.swift`
- Header with branding, DEFCON/Pizza indicator, status stats, and clock.
- Map area with live overlays and selection cards.
- Left/Right panels on iPad for feeds and intelligence.
- Bottom ticker for active conflicts.
- On phone, map with bottom feed panel via `safeAreaInset`.

### Map
File: `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Views/WorldMapView.swift`
- Uses MapKit and overlays for conflicts + live data points.
- Tap markers to open detail cards.
- Debounced fetch of live overlay data based on visible region.

### News Feed
Files:
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Services/NewsFeedService.swift`
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/NewsModels.swift`
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Views/SafariView.swift`

Features:
- Aggregates RSS/Atom feeds in parallel.
- Parses RSS/Atom via XMLParser.
- Shows headlines with source and timestamp.
- Tap opens in in-app Safari view.

### PizzINT (DEFCON / Pizza Threat)
Files:
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Services/PizzIntService.swift`
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Models/PizzIntModels.swift`
- `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Views/WorldMonitorDashboardView.swift`

Features:
- DEFCON level derived from PizzINT data.
- Detail panel with locations + geopolitical tensions.

## Data Sources
### Live Map Overlays
File: `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Services/LiveMapService.swift`
- Intel hotspots and conflict zones: GDELT Geo API (public).
- Military bases: OpenStreetMap Overpass (public).

### News
RSS sources (public, no keys):
- BBC World
- NPR News
- Guardian World
- Reuters World (Google News RSS query)
- Al Jazeera

### PizzINT
- PizzINT dashboard data: `https://www.pizzint.watch/api/dashboard-data`
- PizzINT GDELT tensions: `https://www.pizzint.watch/api/gdelt/batch`

## Data Flow
- `ConflictDataManager` owns all live data and refresh timers.
- News refresh every 5 minutes.
- PizzINT refresh every 10 minutes.
- Map overlays are updated per map region with debounce.

File: `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/Models/ConflictModels.swift`

## Project Structure
- `Views/` — UI components.
- `Models/` — data models.
- `Services/` — network/services.
- `Theme/` — colors, font helpers, and matrix effects.

## Build Notes
- Custom `Info.plist` lives at:
  - `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Info.plist`
- Launch screen:
  - `/Users/jimwashkau/Downloads/JimWas-iOS-DigitalSentenial/Digital Sentinel/Digital Sentinel/LaunchScreen.storyboard`

## Common Tasks
- Add a new map overlay: extend `LiveMapService` and render in `WorldMapView`.
- Add a new feed: update `NewsFeedService.sources`.
- Change DEFCON logic: update `PizzIntService.calculateDefcon`.

## Known Gaps / TODOs
- Clustering for dense map points.
- Toggle controls for map overlays.
- Persistent user preferences for panels and layers.
- Tests for feed parsing and PizzINT calculations.
