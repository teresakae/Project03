//
//  MenuTestApp.swift
//  MenuTest
//
//  Created by Teresa Kae on 24/05/26.
//

/// Use to show state of dish
enum DishLevel: String
{
    case recommended
    case caution
    case safe
    case notSafe
}

import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var isScannerSupported = false
    @State private var tappedDish: DishItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                if isScannerSupported {
                    ScannerView { dish in
                        tappedDish = dish
                    }
                    .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                    Text("Camera not supported on this device")
                        .foregroundColor(.white)
                }

                VStack {
                    HStack {
                        Text("Fdoo")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Spacer()
                        
                        NavigationLink(destination: PreferencesView()) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Spacer()
                    // Language picker placeholder
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkle")
                                .font(.caption)
                            Text("Detect Language")
                                .font(.caption)
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.caption)
                            Text("Indonesia")
                                .font(.caption)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(item: $tappedDish) { dish in
                DishCardView(dish: dish)
            }
        }
        .onAppear {
            isScannerSupported = DataScannerViewController.isSupported
                                 && DataScannerViewController.isAvailable
        }
    }
}

// Temporary dish card view
struct DishCardView: View {
    let dish: DishItem

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: dish.category.iconName) // for Differentiate without color
                Text(dish.category.label)
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(dish.category.color.opacity(0.2))
            .foregroundColor(dish.category.color)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(dish.category.color, lineWidth: 1)
            )

            Text(dish.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                placeholderSection(title: "Description")
                placeholderSection(title: "How to Eat")
                placeholderSection(title: "Culture")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            Spacer()
        }
        .padding()
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(dish.category.color)
    }

    func placeholderSection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray4))
                .frame(height: 60)
        }
    }
}

// Placeholder settings page
struct PreferencesView: View {
    var body: some View {
        Text("Preferences / Onboarding")
            .font(.title2)
            .foregroundColor(.secondary)
            .navigationTitle("Preferences")
    }
}
