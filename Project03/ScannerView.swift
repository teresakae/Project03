import SwiftUI
import VisionKit
import Translation

enum DishCategory {
    case safe, recommended, caution, unsafe

    var uiColor: UIColor {
        switch self {
        case .safe:        return UIColor(named: "StatusSafe")        ?? UIColor(red: 0.13, green: 0.78, blue: 0.37, alpha: 1)
        case .recommended: return UIColor(named: "StatusRecommended") ?? UIColor(red: 0.10, green: 0.60, blue: 1.00, alpha: 1)
        case .caution:     return UIColor(named: "StatusCaution")     ?? UIColor(red: 1.00, green: 0.58, blue: 0.00, alpha: 1)
        case .unsafe:      return UIColor(named: "StatusUnsafe")      ?? UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1)
        }
    }

    var color: Color { Color(uiColor: uiColor) }

    var label: String {
        switch self {
        case .safe:        return "Safe"
        case .recommended: return "Recommended"
        case .caution:     return "Caution"
        case .unsafe:      return "Not Safe"
        }
    }

    var iconName: String {
        switch self {
        case .safe:        return "checkmark.circle.fill"
        case .recommended: return "star.circle.fill"
        case .caution:     return "exclamationmark.triangle.fill"
        case .unsafe:      return "xmark.octagon.fill"
        }
    }
}

struct DishItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let translatedName: String?
    let frame: CGRect
    let category: DishCategory

    static func == (lhs: DishItem, rhs: DishItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

private extension UIFont {
    static func sfRounded(size: CGFloat, weight: UIFont.Weight = .medium) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

struct ScannerView: UIViewControllerRepresentable {
    var topInset:     CGFloat
    var bottomInset:  CGFloat
    var onDishTapped: (DishItem) -> Void
    var translate: ((String) async throws -> String)?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .fast,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner

        let dimmer = UIView()
        dimmer.tag = 888
        dimmer.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        dimmer.isUserInteractionEnabled = false
        dimmer.alpha = 0
        dimmer.translatesAutoresizingMaskIntoConstraints = false
        scanner.overlayContainerView.addSubview(dimmer)
        NSLayoutConstraint.activate([
            dimmer.topAnchor.constraint(equalTo: scanner.overlayContainerView.topAnchor),
            dimmer.bottomAnchor.constraint(equalTo: scanner.overlayContainerView.bottomAnchor),
            dimmer.leadingAnchor.constraint(equalTo: scanner.overlayContainerView.leadingAnchor),
            dimmer.trailingAnchor.constraint(equalTo: scanner.overlayContainerView.trailingAnchor),
        ])
        context.coordinator.dimmerView = dimmer

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scanner.view.addGestureRecognizer(tap)
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        let c = context.coordinator
        c.topInset    = topInset
        c.bottomInset = bottomInset
        c.translate = translate

        let h = uiViewController.view.bounds.height
        guard h > 0, !c.hasSetROI else { return }

        uiViewController.regionOfInterest = CGRect(
            x: 0,
            y: topInset / h,
            width: 1.0,
            height: (h - topInset - bottomInset) / h
        )
        c.hasSetROI = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(onDishTapped: onDishTapped) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onDishTapped: (DishItem) -> Void
        weak var scanner: DataScannerViewController?
        weak var dimmerView: UIView?

        var topInset:    CGFloat = 0
        var bottomInset: CGFloat = 0
        var hasSetROI = false

        var currentDishes:  [DishItem]       = []
        var stableFrames:   [String: CGRect] = [:]
        private let positionThreshold: CGFloat = 10
        private var lastRenderTime: Date = .distantPast
        private var lastItems: [RecognizedItem] = []

        var translate: ((String) async throws -> String)?
        private var translationCache:   [String: String] = [:]
        private var inFlightTranslations: Set<String>    = []

        init(onDishTapped: @escaping (DishItem) -> Void) {
            self.onDishTapped = onDishTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scanner else { return }
            let point = gesture.location(in: scanner.overlayContainerView)
            if let dish = currentDishes.first(where: { $0.frame.contains(point) }) {
                DispatchQueue.main.async { self.onDishTapped(dish) }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            throttledRender(allItems, in: dataScanner)
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            throttledRender(allItems, in: dataScanner)
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            throttledRender(allItems, in: dataScanner)
        }

        func throttledRender(_ items: [RecognizedItem], in scanner: DataScannerViewController) {
            let now = Date()
            guard now.timeIntervalSince(lastRenderTime) > 0.6 else { return }
            lastRenderTime = now
            lastItems = items
            renderOverlays(for: items, in: scanner)
        }

        func renderOverlays(for items: [RecognizedItem], in scanner: DataScannerViewController) {
            var newDishes:        [DishItem]       = []
            var nextStableFrames: [String: CGRect] = [:]

            for item in items {
                guard case .text(let text) = item else { continue }

                let bounds = text.bounds
                let minX   = min(bounds.topLeft.x,    bounds.bottomLeft.x)
                let maxX   = max(bounds.topRight.x,   bounds.bottomRight.x)
                let minY   = min(bounds.topLeft.y,    bounds.topRight.y)
                let maxY   = max(bounds.bottomLeft.y, bounds.bottomRight.y)
                let blobFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

                let lines = text.transcript
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { isValidDishName($0) }

                guard !lines.isEmpty else { continue }

                let lineHeight = blobFrame.height / CGFloat(lines.count)
                let viewHeight = scanner.overlayContainerView.bounds.height
                let viewWidth  = scanner.overlayContainerView.bounds.width
                let bottomBoundary = viewHeight - bottomInset
                let horizontalMargin: CGFloat = 20

                for (index, dishName) in lines.enumerated() {
                    let rawFrame = CGRect(
                        x: blobFrame.origin.x,
                        y: blobFrame.origin.y + lineHeight * CGFloat(index),
                        width: blobFrame.width,
                        height: lineHeight - 2
                    )

                    guard rawFrame.minY >= topInset && rawFrame.maxY <= bottomBoundary else { continue }

                    let stableFrame: CGRect
                    if let prev = stableFrames[dishName],
                       abs(rawFrame.origin.x - prev.origin.x) < positionThreshold,
                       abs(rawFrame.origin.y - prev.origin.y) < positionThreshold {
                        stableFrame = prev
                    } else {
                        stableFrame = rawFrame
                    }
                    nextStableFrames[dishName] = stableFrame

                    let uniformFrame = CGRect(
                        x: horizontalMargin,
                        y: stableFrame.minY,
                        width: viewWidth - horizontalMargin * 2,
                        height: stableFrame.height
                    )

                    newDishes.append(DishItem(
                        name:           dishName,
                        translatedName: translationCache[dishName],
                        frame:          uniformFrame,
                        category:       stableCategory(for: dishName)
                    ))
                }
            }

            let needsTranslation = newDishes.map(\.name).filter {
                translationCache[$0] == nil && !inFlightTranslations.contains($0)
            }

            if !needsTranslation.isEmpty, let translateFn = translate {
                inFlightTranslations.formUnion(needsTranslation)

                Task {
                    await withTaskGroup(of: (String, String?).self) { group in
                        for name in needsTranslation {
                            group.addTask {
                                let result = try? await translateFn(name)
                                return (name, result)
                            }
                        }
                        for await (name, result) in group {
                            await MainActor.run {
                                self.inFlightTranslations.remove(name)
                                if let result {
                                    print("✅ '\(name)' → '\(result)'")
                                    self.translationCache[name] = result
                                } else {
                                    print("⚠️ Translation failed for '\(name)'")
                                }
                            }
                        }
                    }

                    await MainActor.run {
                        self.lastRenderTime = .distantPast
                        if let scanner = self.scanner {
                            self.renderOverlays(for: self.lastItems, in: scanner)
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                for subview in scanner.overlayContainerView.subviews where subview.tag != 888 {
                    subview.removeFromSuperview()
                }
                for dish in newDishes {
                    self.addPill(for: dish, in: scanner.overlayContainerView)
                }
                self.currentDishes  = newDishes
                self.stableFrames   = nextStableFrames
            }
        }

        private func addPill(for dish: DishItem, in container: UIView) {
            let lineH    = dish.frame.height
            let fontSize = min(max(lineH * 0.42, 10), 19)
            let iconSize = min(max(lineH * 0.46, 11), 20)
            let cornerR: CGFloat = min(lineH * 0.38, 12)
            let accentW: CGFloat = 4

            let pill = UIView(frame: dish.frame)
            pill.layer.cornerRadius = cornerR
            pill.layer.cornerCurve  = .continuous
            pill.clipsToBounds      = true
            pill.isUserInteractionEnabled = false

            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            blurView.frame = pill.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pill.addSubview(blurView)

            let tintView = UIView(frame: pill.bounds)
            tintView.backgroundColor  = dish.category.uiColor.withAlphaComponent(0.42)
            tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pill.addSubview(tintView)

            let accentBar = UIView(frame: CGRect(x: 0, y: 0, width: accentW, height: pill.bounds.height))
            accentBar.backgroundColor = dish.category.uiColor
            accentBar.autoresizingMask = [.flexibleHeight]
            pill.addSubview(accentBar)

            let iconView   = UIImageView()
            let iconConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
            iconView.image       = UIImage(systemName: dish.category.iconName, withConfiguration: iconConfig)
            iconView.tintColor   = .white
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            pill.addSubview(iconView)

            let textLabel = UILabel()
            textLabel.textColor     = .white
            textLabel.font          = .sfRounded(size: fontSize, weight: .semibold)
            textLabel.textAlignment = .left
            textLabel.adjustsFontSizeToFitWidth = true
            textLabel.minimumScaleFactor = 0.75
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            pill.addSubview(textLabel)

            NSLayoutConstraint.activate([
                iconView.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
                iconView.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: iconSize),
                iconView.heightAnchor.constraint(equalToConstant: iconSize),
            ])

            if let translated = dish.translatedName {
                textLabel.text = translated
                
                let subLabel = UILabel()
                subLabel.text          = dish.name
                subLabel.textColor     = .white.withAlphaComponent(0.75)
                subLabel.font          = .sfRounded(size: max(fontSize * 0.75, 9), weight: .regular)
                subLabel.translatesAutoresizingMaskIntoConstraints = false
                pill.addSubview(subLabel)

                NSLayoutConstraint.activate([
                    textLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: accentW + 8),
                    textLabel.topAnchor.constraint(equalTo: pill.topAnchor, constant: 3),
                    textLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -6),

                    subLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: accentW + 8),
                    subLabel.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -3),
                    subLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -6),
                ])
            } else {
                textLabel.text = dish.name
                
                NSLayoutConstraint.activate([
                    textLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: accentW + 8),
                    textLabel.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
                    textLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -6),
                ])
            }

            container.addSubview(pill)
        }

        func stableCategory(for name: String) -> DishCategory {
            let all: [DishCategory] = [.safe, .recommended, .caution, .unsafe]
            return all[abs(name.hashValue) % all.count]
        }

        func isValidDishName(_ text: String) -> Bool {
            let t = text.trimmingCharacters(in: .whitespaces)
            guard t.count >= 4 else { return false }
            if t.contains("Rp")         { return false }
            if t.contains("@")          { return false }
            if t.contains("http")       { return false }
            if t.hasPrefix("*")         { return false }
            if t.contains(":")          { return false }
            let low = t.lowercased()
            if low.contains("email")     { return false }
            if low.contains("instagram") { return false }
            if low.contains("alamat")    { return false }
            if t.first?.isNumber == true { return false }
            if t.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) { return false }
            return true
        }
    }
}
