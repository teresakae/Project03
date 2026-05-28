import SwiftUI

struct FoodFlagView: View {
    let category: DishCategory

    var body: some View {
        HStack {
            Image(systemName: category.iconName)
            Text(category.label)
        }
        .font(.caption.bold())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(category.color.opacity(0.2))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(category.color, lineWidth: 1)
        )
    }
}

#Preview("All Categories") {
    VStack {
        ForEach(DishCategory.allCases, id: \.self) { category in
            FoodFlagView(category: category)
        }
    }
}
