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
