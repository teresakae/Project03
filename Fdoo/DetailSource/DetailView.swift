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
                .ignoresSafeArea()

            Color.fdooBG.opacity(0.3).ignoresSafeArea()

            VStack(alignment: .leading) {
                FoodFlagView(category: dish.category)

                Text(dish.translatedName ?? dish.name)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.primary)
                    .padding()

                if dish.translatedName != nil {
                    Text(dish.name)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 8)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

#Preview("Detail Recommended") {
    let dish = DishItem(name: "Nasi Goreng", translatedName: "Fried Rice", frame: .zero, category: .recommended)
    DetailView(dish: dish)
}
