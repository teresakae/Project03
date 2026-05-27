import SwiftUI
import VisionKit
import Translation

private let kTopBarHeight:    CGFloat = 125
private let kBottomBarHeight: CGFloat = 200

enum TranslationError: Error {
    case noSession
}

struct ContentView: View {
    @State private var isScannerSupported  = false
    @State private var tappedDish: DishItem? = nil
    @State private var showInfo            = false
    @State private var showLanguage        = false
    @State private var translationConfig: TranslationSession.Configuration? = nil
    @State private var translationSession: TranslationSession? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                if isScannerSupported {
                    ScannerView(
                        topInset:    kTopBarHeight,
                        bottomInset: kBottomBarHeight,
                        onDishTapped: { tappedDish = $0 },
                        translate: { text in
                            try await translationSession?.translations(
                                from: [TranslationSession.Request(sourceText: text)]
                            ).first?.targetText ?? text
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                    Text("Camera not supported on this device")
                        .foregroundColor(.white)
                }

                VStack {
                    HStack {
                        Text("Fdoo")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Spacer()
                        NavigationLink(destination: PreferencesView()) {
                            Image(systemName: "gear")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.72), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )
                    Spacer()
                }

                VStack(spacing: 0) {
                    Button(action: { showLanguage = true }) {
                        languagePickerPill
                    }
                    shutterRow
                }
                .background(Color.clear)
            }
            .translationTask(translationConfig) { session in
                self.translationSession = session
                do {
                    try await session.prepareTranslation()
                } catch {
                    print("Translation prep failed: \(error)")
                }
            }
            .navigationDestination(item: $tappedDish) { dish in
                DishCardView(dish: dish)
            }
            .sheet(isPresented: $showInfo) {
                NavigationStack {
                    InfoPageView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showInfo = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showLanguage) {
                NavigationStack {
                    LanguageView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showLanguage = false }
                            }
                        }
                }
            }
        }
        .onAppear {
            isScannerSupported = DataScannerViewController.isSupported
                && DataScannerViewController.isAvailable

            translationConfig = TranslationSession.Configuration(
                source: Locale.Language(languageCode: .indonesian),
                target: Locale.Language(languageCode: .english)
            )
        }
    }
    private var languagePickerPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle").font(.caption)
            Text("Detect Language").font(.caption)
            Image(systemName: "arrow.left.arrow.right").font(.caption)
            Text("Indonesia").font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .foregroundColor(.white)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var shutterRow: some View {
        ZStack(alignment: .center) {
            Button(action: { }) {
                LiquidGlassShutter()
            }
            .frame(width: 84, height: 84)

            HStack {
                InfoButton(action: { showInfo = true })
                    .frame(width: 56, height: 56)
                Spacer()
            }
            .padding(.horizontal, 52)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .padding(.bottom, 28)
    }
}

struct LiquidGlassShutter: View {
    @State private var pressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.88), lineWidth: 3.5))
                .frame(width: 84, height: 84)
                .shadow(color: .white.opacity(0.18), radius: 8)
            Circle()
                .fill(.white)
                .frame(width: 64, height: 64)
        }
        .scaleEffect(pressed ? 0.90 : 1.0)
        .animation(.spring(response: 0.20, dampingFraction: 0.55), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

struct InfoButton: View {
    var action: () -> Void
    @State private var pressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 1.5))
                .frame(width: 54, height: 54)
            Image(systemName: "info.circle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
        }
        .scaleEffect(pressed ? 0.88 : 1.0)
        .animation(.spring(response: 0.20, dampingFraction: 0.55), value: pressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in
                    pressed = false
                    action()
                }
        )
    }
}

struct DishCardView: View {
    let dish: DishItem

    var body: some View {
        dish.category.color
            .ignoresSafeArea()
            .navigationTitle(dish.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PreferencesView: View {
    var body: some View {
        Text("Preference Settings")
            .font(.title)
            .foregroundColor(.secondary)
            .navigationTitle("Preferences")
    }
}

struct InfoPageView: View {
    var body: some View {
        ZStack {
            Color.clear
            Text("Info Screen")
        }
        .navigationTitle("How to Say")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguageView: View {
    var body: some View {
        ZStack {
            Color.clear
            Text("Language Picker")
        }
        .navigationTitle("Language Picker")
        .navigationBarTitleDisplayMode(.inline)
    }
}
