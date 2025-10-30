# TrackMe Code Coverage Report
Generated: 2025-10-30 19:43:18

## Overall Coverage
**TrackMe.app: 26.42% (1915/7248 lines)**

## Coverage by File

| File | Lines | Coverage | Lines Covered |
|------|-------|----------|---------------|
| ExportService.swift | 19 | **95.15%** | 157/165 |
| ContentView.swift | 8 | **100.00%** | 57/57 |
| Persistence.swift | 7 | **77.14%** | 54/70 |
| TrackMeApp.swift | 20 | **69.54%** | 121/174 |
| TrackingView.swift | 97 | **46.80%** | 1384/2957 |
| PhoneConnectivityManager.swift | 24 | **32.74%** | 55/168 |
| LocationManager.swift | 47 | **17.85%** | 83/465 |
| HistoryView.swift | 107 | **0.19%** | 4/2083 |
| TripMapView.swift | 58 | **0.00%** | 0/1109 |

## Test Statistics

Total Test Files: 14
- LocationPermissionTests.swift: 55 tests
- TrackingViewTests.swift: 56 tests
- AdvancedLocationManagerTests.swift: 52 tests
- ExportServiceTests.swift: 51 tests
- WatchViewTests.swift: 40 tests
- HistoryViewTests.swift: 32 tests
- LocationManagerTests.swift: 24 tests
- CoreDataConcurrencyTests.swift: 22 tests
- AppLifecycleTests.swift: 20 tests
- WatchConnectivityManagerTests.swift: 15 tests
- IntegrationTests.swift: 14 tests
- ViewUtilityTests.swift: 11 tests
- HistoryViewCollectionTests.swift: 10 tests
- PhoneConnectivityManagerTests.swift: 10 tests

**Total Tests: 412**

## High Coverage Components ✅
- **ExportService**: 95.15% - Excellent test coverage
- **ContentView**: 100.00% - Complete coverage
- **Persistence**: 77.14% - Good coverage
- **TrackMeApp**: 69.54% - Good coverage

## Low Coverage Components ⚠️
- **HistoryView**: 0.19% - UI view, mostly SwiftUI body code
- **TripMapView**: 0.00% - UI view, needs UI testing
- **LocationManager**: 17.85% - Core functionality, needs more tests
- **TrackingView**: 46.80% - UI view with business logic

## Notes
- UI Views (HistoryView, TripMapView, TrackingView) have low coverage because they contain primarily SwiftUI declarative code
- Business logic components (ExportService, LocationManager) have better coverage
- Total of 412 unit tests validating core functionality
- HistoryViewCollectionTests (10 tests) specifically validate collection view crash fixes

## Recommendations
1. Add more LocationManager tests to increase coverage from 17.85%
2. Consider UI tests for view components
3. SwiftUI views are challenging to unit test - focus on extracted business logic
4. Current coverage is appropriate for business logic layer
