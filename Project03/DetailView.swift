//
//  DetailView.swift
//  MenuTest
//
//  Created by Brent Deverman on 5/26/26.
//

import SwiftUI

struct DetailView: View {
    
    var body: some View {
        
        
        ZStack {
            Image("menusample")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack {
                Text("Hello, World!")
                
            }
            .padding()
            .background(.ultraThinMaterial)
            
            
        }
    }
}

#Preview {
    DetailView()
}
