//
//  DetailView.swift
//  MenuTest
//
//  Created by Brent Deverman on 5/26/26.
//

import SwiftUI

struct DetailView: View {
    
    var body: some View {
        Image("menusample")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        
    }
}

#Preview {
    DetailView()
}
