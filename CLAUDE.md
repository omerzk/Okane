# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Okane is an iOS SwiftUI application for managing Shufersal (Israeli supermarket chain) digital coupons. The app extracts coupon URLs from SMS messages, fetches barcode data from web pages, generates Code128 barcodes, and provides an optimized coupon selection interface.

## Architecture

### Current Structure - Single File
- **ContentView.swift**: Contains the entire application (~2000 lines)
- All models, views, business logic, and utilities are in one file
- This can be broken down into separate files when making significant changes

### Suggested File Structure (for future refactoring)
```
Okane/
├── Models/
│   ├── Coupon.swift
│   ├── CouponError.swift
│   └── CouponStore.swift
├── Views/
│   ├── ContentView.swift
│   ├── BarcodeView.swift
│   ├── AddCouponView.swift
│   ├── BulkImportView.swift
│   └── Components/
│       ├── CouponRowView.swift
│       ├── CollapsibleStatsHeaderView.swift
│       └── OptimizationHeaderView.swift
├── Utilities/
│   ├── NetworkRetryHelper.swift
│   ├── BarcodeGenerator.swift
│   └── SMSParser.swift
├── Extensions/
│   └── Color+Theme.swift
└── AppIntents/
    └── AddCouponIntent.swift
```

### Core Components
- **CouponStore**: Main data store using UserDefaults for persistence
- **Coupon Model**: Contains URL, barcode number, value, date, usage status, and original SMS
- **App Intents**: AddCouponIntent for SMS integration with Siri shortcuts
- **Optimization Algorithm**: Dynamic programming for optimal coupon selection

### Key Features
1. **SMS Processing**: Extracts URLs and values using regex patterns
2. **Web Scraping**: Fetches HTML from coupon URLs to extract barcode data
3. **Barcode Generation**: Creates Code128 barcodes using Core Image
4. **Coupon Optimization**: Finds best coupon combinations for target amounts
5. **Bulk Import**: Supports multiple coupons from text or files

## Development Commands

### Building and Running
```bash
# Open in Xcode
open Okane.xcodeproj

# Build from command line
xcodebuild -project Okane.xcodeproj -scheme Okane -configuration Debug

# Clean build
xcodebuild clean -project Okane.xcodeproj -scheme Okane
```

### Development Environment
- **Xcode**: 15.2+
- **iOS Target**: 17.2+
- **Swift**: 5.0
- **Platform**: iPhone only
- **Dependencies**: AppIntents.framework (system)

## Key Technical Details

### Data Processing Pipeline
1. SMS message → URL extraction (regex: `https://[^\s]+`)
2. Value extraction (Hebrew patterns: `בסך\s*₪(\d+\.?\d*)`)
3. Network request → HTML fetch (with retry logic)
4. HTML parsing → barcode extraction (`<img alt="(\d+)" src="(bar\.ashx\?[^"]+)"`)
5. Code128 barcode generation (CIFilter)
6. UserDefaults persistence

### Optimization Algorithm
Dynamic programming approach for coupon selection:
- Converts to cents for precision
- Knapsack algorithm for maximum value under target
- Prioritizes older coupons for ties
- Returns specific coupon combination

### Error Handling
- **NetworkRetryHelper**: Exponential backoff
- **CouponError**: Typed error cases
- **Duplicate Prevention**: URL and barcode checking
- **Graceful Failures**: Continues on individual errors

## Code Patterns

### State Management
- `@StateObject` for CouponStore
- `@Published` for reactive updates
- `MainActor` for UI thread safety
- `async/await` for network calls

### UI Patterns
- Custom color extensions (warmOrange, okamiGold, etc.)
- Collapsible headers with scroll tracking
- Sheet presentations for modals
- Spring animations for state changes

### Data Persistence
- UserDefaults with JSON encoding
- Structure versioning for migrations
- Fallback to empty state on decode errors

## Common Tasks

### Adding New Views
When creating new views, consider breaking them into separate files:
```swift
// New file: Views/Components/NewFeatureView.swift
import SwiftUI

struct NewFeatureView: View {
    // Implementation
}
```

### Extending CouponStore
Add new functionality to the store:
```swift
extension CouponStore {
    func newFeature() async {
        // Implementation
    }
}
```

### Testing
- Manual testing in Xcode simulator
- Test with real Shufersal SMS messages
- Validate network error scenarios
- Test optimization with various coupon sets

## Development Notes

- Feel free to break down ContentView.swift when making significant changes
- Follow existing color palette and animation patterns
- Maintain thread safety with MainActor annotations
- Use the existing error handling patterns
- Keep the Hebrew text parsing patterns updated if Shufersal changes their SMS format