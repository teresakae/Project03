import SwiftUI

struct DetailView: View {
    let dish: DishItem
    @State private var isHowtoEatExpanded = true
    @State private var isCultureExpanded = true

    var body: some View {
        ZStack {
//            Image("menusample")
//                .resizable()
//                .scaledToFill()
//                .grayscale(1.0)
//                .blur(radius: 5)

            Color.fdooBG.opacity(0.3)

            // would like to wrap in scroll view but it moves the card to top of screen
            ScrollView {
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
                    
                    DisclosureGroup(isExpanded: $isHowtoEatExpanded) {
                        VStack(alignment: .leading) {Text("The traditional way to eat this is with your hand.")
                        }
                    } label: {
                        Text("How to Eat").font(.title3).bold().foregroundStyle(
                            .primary
                        )
                    }
                    DisclosureGroup(isExpanded: $isCultureExpanded) {
                        VStack(alignment: .leading) {Text("Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet.")
                        }
                    } label: {
                        Text("Culture").font(.title3).bold().foregroundStyle(
                            .primary
                        )
                    }
                    
                }
                .padding()
            }
            .glassEffect()
//            .shadow(radius: 8)
//            .padding(.horizontal, 24)
//            .padding(.vertical, 40)

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


#Preview("Sheet View") {
    
    @Previewable @State var showSheet = true
    
    Color.clear
        .sheet(isPresented: $showSheet)
    {
        DetailView(dish: DishItem(
                        name: "Nasi Goreng",
                        translatedName: "Fried Rice",
                        frame: .zero,
                        category: .recommended
                    ))
        .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
    }
}
