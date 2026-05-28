//
//  TranslateView.swift
//  Project03
//
//  Created by Luisa Haning Tyas on 27/05/26.
//
import SwiftUI

struct TranslateView: View {
    var body: some View {
        VStack {
            VStack (alignment: .leading) {
                VStack (alignment: .leading){
                    Text("English (EN)")
                    Text("I can't eat pork and shrimp.")
                }
                .foregroundStyle(Color.primary)
                Divider()
                VStack (alignment: .leading){
                    HStack{
                        Text("Indonesian (IDN)")
                        Spacer()
                        Image(systemName: "speaker.wave.2.circle.fill")
                    }
                    
                    HStack{
                        Text("Saya tidak bisa makan daging babi dan udang")
                        //                    Spacer()
                        //                    Image(systemName: "speaker.wave.2.circle.fill")
                    }
                }
                
                .foregroundStyle(Color.fdooTertiary)
                
            }
            .padding()
            .background(Color.fdooBG)
            .cornerRadius(20)
            .padding()
            Spacer()
        }

    }
        
}

#Preview {
    TranslateView()
}
