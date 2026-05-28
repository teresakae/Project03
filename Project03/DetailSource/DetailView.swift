//
//  DetailView.swift
//  MenuTest
//
//  Created by Brent Deverman on 5/26/26.
//

import SwiftUI
import Playgrounds

struct DetailView: View {
    
    let dish: DishItem
    
    var body: some View {
        
        
        ZStack {
            // fake menu from camera in the background
            Image("menusample")
                .resizable()
                .scaledToFill()
                .grayscale(1.0)
                .blur(radius: 5)
                .ignoresSafeArea()
            
            // dim layer for contrast & apply tint from design
            Color.fdooBG.opacity(0.3).ignoresSafeArea()
            
            ZStack {
                VStack (alignment: .leading) {
                    FoodFlagView(category: dish.category)
                    HStack(alignment: .top)
                    {
                        Text(dish.name)
                            .font(.title)
                            .bold()
                            .foregroundStyle(.primary)
                            .padding()
                    }
                    
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 8)
                .padding()

            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()

    
    }
}

#Preview("Detail Recommended") {
    let x = DishItem.init(name: "Nasi Goreng", frame: .zero, category: .recommended)

    DetailView(dish: x)
}

#Preview("Detail Caution") {
    let x = DishItem.init(name: "Nasi Goreng", frame: .zero, category: .caution)

    DetailView(dish: x)
}

#Preview("Detail Safe") {
    let x = DishItem.init(name: "Nasi Goreng", frame: .zero, category: .safe)

    DetailView(dish: x)
}

#Preview("Detail Safe") {
    let x = DishItem.init(name: "Nasi Goreng", frame: .zero, category: .unsafe)

    DetailView(dish: x)
}


#Preview("Temp Detail View") {
    
    let x = DishItem.init(name: "Nasi Goreng", frame: .zero, category: .caution)
    DishCardView(dish: x)
}
