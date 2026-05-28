//
//  FoodFlagView.swift
//  Project03
//
//  Created by Brent Deverman on 5/28/26.
//

import SwiftUI

struct FoodFlagView: View {
    let category: DishCategory
    var body: some View {
        ZStack{
            Color(category.color)
            HStack {
                Image(systemName: category.iconName)
                Text(category.label)
            }
            .padding()
        }
        
    }
}

#Preview("All Categories") {
    
    ForEach(DishCategory.allCases, id: \.self) { category in
        FoodFlagView(category: category)
    }
    
}
