import SwiftUI

// Helper to get consistent colors for store names
struct StoreColorHelper {
    static func colorForStore(_ storeName: String) -> (primary: Color, secondary: Color) {
        let hash = storeName.hashValue
        let colorOptions: [(Color, Color)] = [
            (Color.warmOrange, Color.warmAmber),
            (Color(red: 0.9, green: 0.6, blue: 0.3), Color(red: 0.95, green: 0.7, blue: 0.4)),
            (Color(red: 0.85, green: 0.5, blue: 0.2), Color(red: 0.9, green: 0.65, blue: 0.35)),
            (Color(red: 0.95, green: 0.65, blue: 0.25), Color(red: 0.98, green: 0.75, blue: 0.45))
        ]

        // "All" always gets the primary orange
        if storeName == "All" {
            return colorOptions[0]
        }

        let index = abs(hash) % colorOptions.count
        return colorOptions[index]
    }
}

struct StoreFilterView: View {
    @ObservedObject var store: CouponStore

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    ForEach(store.availableStores.reversed(), id: \.self) { storeName in
                        StoreFilterButton(
                            storeName: storeName == "All" ? "הכל" : storeName,
                            isSelected: (storeName == "All" && store.selectedStore == nil) ||
                                       (storeName == store.selectedStore),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    store.selectStore(storeName)
                                }
                            }
                        )
                    }
                }
                .frame(minWidth: geometry.size.width, alignment: .trailing)
                .padding(.vertical, 4)
                .padding(.trailing, 20)
            }
        }
        .frame(height: 40)
    }
}

struct StoreFilterButton: View {
    let storeName: String
    let isSelected: Bool
    let action: () -> Void

    private var storeColor: (primary: Color, secondary: Color) {
        StoreColorHelper.colorForStore(storeName)
    }

    var body: some View {
        Button(action: action) {
            Text(storeName)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [storeColor.primary, storeColor.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.cardBackground, Color.cardBackground],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? Color.clear : storeColor.primary.opacity(0.25),
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .shadow(
            color: isSelected ? storeColor.primary.opacity(0.25) : Color.clear,
            radius: 6,
            x: 0,
            y: 2
        )
    }
}
