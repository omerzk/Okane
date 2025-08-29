import SwiftUI
import Foundation
import Combine
import UniformTypeIdentifiers
import AppIntents

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Enhanced Views with Okami Aesthetics
struct ContentView: View {
    @StateObject private var store = CouponStore()
    @State private var showingAddCoupon = false
    @State private var showingBulkImport = false
    @State private var searchText = ""
    @State private var optimizationResults: [Coupon] = []
    @State private var optimizationTarget: Double = 0
    @State private var sortAscending = false
    @State private var scrollOffset: CGFloat = 0
    @State private var cachedFilteredCoupons: [Coupon] = []
    
    private func performOptimization() {
            // Clear previous results
            optimizationResults = []
            optimizationTarget = 0
            
            // Validate and clean input
            let cleanedInput = searchText.replacingOccurrences(of: "₪", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let searchValue = Double(cleanedInput), searchValue > 0 else {
                return
            }
            
            optimizationTarget = searchValue
            optimizationResults = findOptimalCouponCombination(target: searchValue, availableCoupons: store.filteredCoupons)
        }
        
        private func clearOptimization() {
            optimizationResults = []
            optimizationTarget = 0
        }
    
    var filteredCoupons: [Coupon] {
        // If we have optimization results, show them
        if !optimizationResults.isEmpty {
            return optimizationResults.filter { !$0.isUsed }
        }
        
        // Use cached results if available
        return cachedFilteredCoupons
    }
    
    private func updateFilteredCoupons() {
        let baseCoupons = store.filteredCoupons
        
        // Perform expensive sorting operation once
        cachedFilteredCoupons = baseCoupons.sorted { coupon1, coupon2 in
            if sortAscending {
                return coupon1.dateAdded < coupon2.dateAdded
            } else {
                return coupon1.dateAdded > coupon2.dateAdded
            }
        }
    }
    
    private func findOptimalCouponCombination(target: Double, availableCoupons: [Coupon]) -> [Coupon] {
        // Filter only unused coupons for optimization
        let unusedCoupons = availableCoupons.filter { !$0.isUsed }
        
        // Sort coupons: by value ASC, then by date ASC (older first for ties)
        let sortedCoupons = unusedCoupons.sorted { coupon1, coupon2 in
            if coupon1.value == coupon2.value {
                return coupon1.dateAdded < coupon2.dateAdded
            }
            return coupon1.value < coupon2.value
        }
        
        let targetCents = Int(target * 100) // Work with cents to avoid floating point issues
        let n = sortedCoupons.count
        
        if n == 0 || targetCents <= 0 {
            return []
        }
        
        // DP with item tracking: dp[i][w] = max value achievable using first i items with weight limit w
        var dp = Array(repeating: Array(repeating: 0, count: targetCents + 1), count: n + 1)
        
        // Fill DP table
        for i in 1...n {
            let couponValue = Int(sortedCoupons[i-1].value * 100)
            
            for w in 0...targetCents {
                // Don't take current coupon
                dp[i][w] = dp[i-1][w]
                
                // Take current coupon if it fits
                if couponValue <= w {
                    let valueWithCoupon = dp[i-1][w - couponValue] + couponValue
                    dp[i][w] = max(dp[i][w], valueWithCoupon)
                }
            }
        }
        
        // Find the maximum value achieved
        let maxValue = dp[n][targetCents]
        
        if maxValue == 0 {
            return []
        }
        
        // Backtrack to find which coupons were selected
        var result: [Coupon] = []
        var w = targetCents
        
        for i in stride(from: n, through: 1, by: -1) {
            // If dp[i][w] != dp[i-1][w], then coupon i-1 was included
            if dp[i][w] != dp[i-1][w] {
                result.append(sortedCoupons[i-1])
                w -= Int(sortedCoupons[i-1].value * 100)
            }
        }
        
        // Sort result by date (older first)
        return result.sorted { $0.dateAdded < $1.dateAdded }
    }
    
    var headerHeight: CGFloat {
        let baseHeight: CGFloat = 400
        let minHeight: CGFloat = 140
        let scrollThreshold: CGFloat = 200
        
        if scrollOffset <= 0 {
            return baseHeight
        } else if scrollOffset >= scrollThreshold {
            return minHeight
        } else {
            let progress = scrollOffset / scrollThreshold
            return baseHeight - (baseHeight - minHeight) * progress
        }
    }
    
    private func updateOptimizationResults() {
        // Remove used coupons from optimization results
        optimizationResults = optimizationResults.filter { !$0.isUsed }
        
        // If all coupons in the optimization are now used, clear the results
        if optimizationResults.isEmpty && optimizationTarget > 0 {
            clearOptimization()
        }
    }

    var backgroundView: some View {
        ZStack {
            Color.okamiParchment
                .ignoresSafeArea()

            OrganiqueShape(variant: 1)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.okamiGold.opacity(0.08),
                            Color.okamiAmber.opacity(0.06),
                            Color.okamiEarth.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(-15))
                .scaleEffect(1.2)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView

                mainContentView
            }
            .navigationTitle("Okane")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    colors: [Color.warmOrange, Color.warmAmber],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                for: .navigationBar
            )
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingAddCoupon) {
                AddCouponView(store: store)
            }
            .sheet(isPresented: $showingBulkImport) {
                BulkImportView(store: store)
            }
            .overlay {
                if store.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
                Button("OK") {
                    store.errorMessage = nil
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
            .alert("Network Error", isPresented: .constant(store.retryableError != nil)) {
                Button("Retry") {
                    Task {
                        await store.retryCoupon()
                    }
                }
                Button("Cancel") {
                    store.dismissRetryError()
                }
            } message: {
                Text(store.retryableError ?? "")
            }
        }
        .onAppear {
            updateFilteredCoupons()
        }
        .onChange(of: store.coupons) { _, _ in
            updateFilteredCoupons()
        }
        .onChange(of: store.showUsedCoupons) { _, _ in
            updateFilteredCoupons()
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation(.spring()) {
                        sortAscending.toggle()
                        updateFilteredCoupons()
                    }
                }) {
                    Image(systemName: sortAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .shadow(color: .okamiGold.opacity(0.3), radius: 4, x: 0, y: 0)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddCoupon = true }) {
                        Label("Add Single Coupon", systemImage: "plus.circle")
                    }
                    
                    Button(action: { showingBulkImport = true }) {
                        Label("Bulk Import", systemImage: "square.and.arrow.down.on.square")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            store.showUsedCoupons.toggle()
                        }
                    }) {
                        Label(
                            store.showUsedCoupons ? "Hide Used" : "Show Used",
                            systemImage: store.showUsedCoupons ? "eye.slash.fill" : "eye.fill"
                        )
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .shadow(color: .okamiGold.opacity(0.3), radius: 4, x: 0, y: 0)
                }
                .disabled(store.isLoading)
            }
        }
    }
    
    var mainContentView: some View {
        VStack(spacing: 0) {
            if store.coupons.isEmpty {
                Spacer()
                EmptyStateView()
                Spacer()
            } else {
                scrollableContentView
            }
        }
    }
    
    var scrollViewContent: some View {
        List {
            // Full header
            CollapsibleStatsHeaderView(
                store: store,
                displayedCoupons: filteredCoupons,
                height: headerHeight,
                scrollOffset: scrollOffset
            )
            .padding(.horizontal, 20)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            // Optimization header when showing search results
            if !optimizationResults.isEmpty {
                OptimizationHeaderView(
                    target: optimizationTarget,
                    suggestions: optimizationResults
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            // Scroll offset tracking
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
            }
            .frame(height: 0)
            .padding(.bottom, -12)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            // Coupons list
            ForEach(filteredCoupons, id: \.id) { coupon in
                CouponRowView(coupon: coupon, store: store) {
                    optimizationResults = optimizationResults.filter { !$0.isUsed }
                    if optimizationResults.isEmpty && optimizationTarget > 0 {
                        clearOptimization()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }

            // Spacer at bottom
            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = max(0, -value + 100.0)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: store.showUsedCoupons)
    }

    var scrollableContentView: some View {
        scrollViewContent
            .searchable(text: $searchText, prompt: "How much?")
            .onSubmit(of: .search) {
                performOptimization()
            }
            .onChange(of: searchText) { oldValue, newValue in
                // If search text becomes empty (cancel pressed), clear optimization
                if newValue.isEmpty {
                    clearOptimization()
                    return
                }

                // Clear results when user starts typing again
                if !newValue.isEmpty && newValue != oldValue {
                    clearOptimization()
                }

                // Filter input to only allow positive numbers and ₪ symbol
                let filtered = newValue.filter { char in
                    char.isNumber || char == "." || char == "₪"
                }

                if filtered != newValue {
                    searchText = filtered
                }
            }
    }
}

@main
struct OkaneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        AddCouponShortcuts.updateAppShortcutParameters()
    }
}