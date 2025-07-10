# Codebase Feature Review Plan

## Notes

- The codebase is an ADS-B aircraft tracking app for iOS and watchOS.
- Built with SwiftUI for UI and code is modular and uses shared logic for iOS and watchOS targets.
- Core features include real-time aircraft and airport display on a map using MapKit, user location integration via a singleton LocationManager, and dynamic polling based on map zoom/location.
- Aircraft data is fetched from remote ADS-B API endpoints (regular, military, PIA, LADD) using AircraftService, which manages polling, caching, filtering, and error handling. Polling interval is dynamically adjusted based on map zoom level.
- Aircraft and airport models are comprehensive, supporting detailed attributes, flexible value parsing (FlexibleValue), and manufacturer mapping. Aircraft model supports decoding from variable API formats and includes computed properties for display.
- Aircraft model initialization in previews relies on decoding from JSON using realistic sample data (see PreviewData/AircraftData.swift), not manual struct initialization.
- When creating preview/test data for Aircraft, always use JSON decoding via PreviewAircraftData for accuracy and to match production data format.
- App includes photo fetching for aircraft using AircraftPhotoService, with image caching and fallback logic. AircraftDetailView displays photos, navigation modes, and emergency status.
- App lifecycle is managed by AppLifecycleManager to optimize polling and data usage, handling scene phase changes and location updates.
- UI includes filter controls (MapFilterView, MapFilterControlView), legend (MapLegendView), aircraft detail views, list view (ListView), and user location controls (MapUserLocationControlView). MapStyleControlView allows switching between map types.
- SettingsView provides user configuration for unit preferences, info box display, and search range. User preferences are persisted using AppStorage.
- Utilities include AircraftDisplayConfig for icon/type mapping, formatters for numbers/units, and helpers for map interaction. AircraftDisplayConfig is a utility, not a module—no import needed, just file inclusion. Recent fix: removed unnecessary SwiftCore import from AircraftMarkerView to resolve AircraftType reference.
- Map rendering performance has been completely overhauled and optimized. The app now runs smoothly with 500+ aircraft and can handle the full dataset (1194 aircraft) without significant lag.
- Replaced complex reactive data binding system with simple, non-reactive approach to eliminate AttributeGraph cycles and state modification warnings.
- All Swift compilation errors in MapView.swift and AircraftMarkerView.swift have been fixed.
- 3-color system - white (default civilian), red (emergency), green (military with conservative callsign detection).

## Task List

- [x] Identify and list key files and services
- [x] Analyze AircraftService and AppLifecycleManager for data flow and polling logic
- [x] Review MapView for UI and user interaction features
- [x] Summarize Aircraft and Airport models
- [x] Review remaining views and utilities for additional features
- [x] Compile complete list of current features and use cases
- [x] Analyze map rendering bottlenecks with large aircraft lists
- [x] Audit and refactor polling logic for reliability and efficiency
- [x] Redesign data management for performance (caching, diffing, update throttling)
- [x] Address severe lag and performance issues when zoomed out on map
- [x] Validate and monitor map performance optimizations
- [x] Implement proper aircraft color coding system (white/red/green)
- [x] Eliminate AttributeGraph cycles and state modification warnings
- [x] Implement async data updates to prevent UI lag
- [x] Fix military aircraft detection to use conservative callsign-based approach

## Current Status

✅ **OPTIMIZATION AND CLEANUP COMPLETE** - The app now runs smoothly with full aircraft datasets, has a clean codebase, and includes comprehensive user experience improvements.

## Performance Optimization Summary

### 🚀 Key Improvements Made:

1. **Data Management Overhaul**

   - Replaced @ObservedObject reactive bindings with manual timer-based updates
   - Eliminated AttributeGraph cycles and "Modifying state during view update" warnings
   - Implemented async data fetching to prevent UI lag during updates

2. **Simplified Aircraft Rendering**

   - Optimized AircraftMarkerView with proper color coding
   - Reduced update frequency (10-second intervals) to minimize load

3. **Aircraft Color System**
   - White: Default civilian aircraft
   - Red: Emergency aircraft (aircraft.isEmergency)
   - Green: Military aircraft

### 📊 Performance Results:

- **Before**: Severe lag with ~1000 aircraft, frequent AttributeGraph cycles, unusable map interaction
- **After**: Smooth performance with all available aircraft, no cycles, responsive map interaction
- **Update intervals**: Dynamic 5-30 seconds based on zoom level (optimized from frequent reactive updates)
- **Codebase**: Cleaned up by removing 4 unused files and experimental functionality

### 🔧 Technical Implementation:

- **MapView.swift**: Completely rewritten with non-reactive approach and original UI design
- **Smart data management**: Area-based fetching (zoom >6), 100km pan threshold, data flushing
- **Error handling**: Integrated MessageManager for user-friendly service outage notifications
- **Data flow**: AircraftService.shared → Timer-based fetch → Simple state arrays → Direct rendering

## ✅ Recent Improvements

### Codebase Cleanup - COMPLETED

- **Cleaned up experimental code**: Removed old performance monitoring and complex filtering logic

### Map Center Tracking - COMPLETED

- **Issue**: Aircraft data was fetched for user's initial location, not current map view center
- **Solution**: Implemented debounced map center tracking with 100km threshold
- **Implementation**: Added `updateAircraftServiceLocation` with smart distance filtering and fast polling after map changes
- **Performance**: Only triggers API calls when map center moves >100km (optimized for 250nm/463km radius)

### Aircraft Icon Rotation - COMPLETED

- **Issue**: Aircraft icons didn't point in their actual heading direction
- **Solution**: Added 90-degree rotation offset to aircraft track values
- **Implementation**: Modified aircraft markers to use `rotationEffect(.degrees((aircraft.track ?? 0) - 90))`

### Aircraft Flickering Fix - COMPLETED

- **Issue**: Aircraft randomly disappeared and reappeared during zoom/pan operations
- **Solution**: Redesigned aircraft markers with consistent view structure
- **Implementation**: Eliminated conditional view structure changes that caused SwiftUI to recreate view hierarchy

### Refresh Interval Optimization - COMPLETED

- **Issue**: City-level zoom had 11+ second refresh intervals instead of expected 5s
- **Solution**: Redesigned zoom-based refresh interval calculation
- **New intervals**:
  - Zoom 15+ (city/street): 5 seconds
  - Zoom 5-15 (regional): 5-30 seconds (exponential scaling)
  - Performance optimized with 5s minimum, 30s maximum

### Swift 6 Concurrency Compliance - COMPLETED

- **Issue**: Swift 6 compiler errors for concurrent variable mutation
- **Solution**: Added `@MainActor` annotations and proper concurrency handling
- **Implementation**: Fixed `startFastPollingForMapChange` method with MainActor context

### Area-Based Data Fetching - COMPLETED

- **Issue**: Unnecessary API calls when zoomed out at country level
- **Solution**: Only fetch area-specific data when zoom level > 6
- **Implementation**: Added zoom level check and smart data flushing when switching areas

### Error Message Integration - COMPLETED

- **Issue**: No user feedback during API outages or service issues
- **Solution**: Integrated with SwiftCore MessageManager for consistent error display
- **Implementation**: Shows user-friendly messages when service hasn't updated for >60 seconds

## 🏁 Project Status

### ✅ Major Achievements Completed:

1. **Performance Crisis Resolved**: Fixed severe lag and AttributeGraph cycles
2. **Scalability Achieved**: Smooth performance with full aircraft datasets
3. **User Experience Enhanced**:
   - Proper aircraft icon rotation and colors
   - Dynamic zoom-based refresh intervals
   - Smart area-based data fetching
   - User-friendly error messages
4. **Code Quality Improved**:
   - Removed 4 unused files and experimental code
   - Simplified architecture with direct rendering
   - Swift 6 compliance

### 📈 Current Performance Metrics:

- **Aircraft capacity**: Unlimited (no artificial 500 aircraft limit)
- **Refresh intervals**: 5s (city/street) to 30s (country) based on zoom
- **Map responsiveness**: Smooth pan/zoom with no flickering
- **Memory usage**: Optimized through cleanup and simplified rendering
- **Error handling**: Integrated with SwiftCore MessageManager

## 🔄 Future Improvements

### Initial Data Load Optimization

- **Issue**: Aircraft data takes ~5 seconds to load when app starts
- **Root cause**: App waits for AppLifecycleManager → LocationManager → AircraftService initialization sequence
- **Current workaround**: Fast polling (0.2s intervals) until data appears, then slow polling
- **Priority**: Low (performance acceptable, optimization would be nice-to-have)
