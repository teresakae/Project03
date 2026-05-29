import SwiftUI

struct DetailView: View {
    let dish: DishItem

    var body: some View {
        ZStack {
            Image("menusample")
                .resizable()
                .scaledToFill()
                .grayscale(1.0)
                .blur(radius: 5)

            Color.fdooBG.opacity(0.3)

            VStack(alignment: .leading, spacing: 12) {
                FoodFlagView(category: dish.category)

                Text(dish.translatedName ?? dish.name)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.primary)

                if dish.translatedName != nil {
                    Text(dish.name)
                        .font(.title3)
                }

                HStack(spacing: 6) {
                    // hard code pronounciation
                    Text("| ˈnɑːsiː ɡɒˈrɛŋ ˈaɪæm |")
                    Image(systemName: "speaker.wave.2.circle.fill")
                }.font(.title3)
                    .padding(.bottom)
                // Must put hard coded text here
                Text(
                    "Fried rice with chicken topped with fried sunny side up egg."
                )
                .lineLimit(nil)
                // here will be pills hard coded for now
                HStack {
                    Text("🍗 Chicken")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThickMaterial, in: Capsule())
                    Text("🥚 Egg")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThickMaterial, in: Capsule())
                    Text("🍚 Rice")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThickMaterial, in: Capsule())
                }

            }
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(radius: 8)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .ignoresSafeArea()
    }
}

#Preview("Detail Recommended") {
    let dish = DishItem(
        name: "Nasi Goreng",
        translatedName: "Fried Rice",
        frame: .zero,
        category: .recommended
    )
    DetailView(dish: dish)
}
