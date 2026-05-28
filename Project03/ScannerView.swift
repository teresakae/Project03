//
//  ScannerView.swift
//  Project03
//
//  Created by Teresa Kae on 24/05/26.
//

import SwiftUI
import VisionKit

enum DishCategory: CaseIterable {
    case safe, recommended, caution, unsafe
    // SwiftUI (in ContentView)
    var color: Color {
        switch self {
        case .safe:        return .statusSafe
        case .recommended: return .statusRecommended
        case .caution:     return .statusCaution
        case .unsafe:      return .statusUnsafe
        }
    }

    // UIKit (camera boxes in ScannerView)
    var uiColor: UIColor {
        switch self {
        case .safe:        return UIColor(named: "StatusSafe") ?? .systemGreen
        case .recommended: return UIColor(named: "StatusRecommended") ?? .systemBlue
        case .caution:     return UIColor(named: "StatusCaution") ?? .systemOrange
        case .unsafe:      return UIColor(named: "StatusUnsafe") ?? .systemRed
        }
    }

    var label: String {
        switch self {
        case .safe:        return "Safe"
        case .recommended: return "Recommended"
        case .caution:     return "Caution"
        case .unsafe:      return "Not Safe"
        }
    }
    
    // Differentiate without color
    var iconName: String {
        switch self {
        case .safe:        return "checkmark.circle.fill"
        case .recommended: return "star.circle.fill"
        case .caution:     return "exclamationmark.triangle.fill"
        case .unsafe:      return "xmark.octagon.fill"
        }
    }
}

// Item model (open to changes)
struct DishItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let frame: CGRect // X/Y coords and width/height of the text on the screen
    let category: DishCategory
    
    static func == (lhs: DishItem, rhs: DishItem) -> Bool {
        lhs.id == rhs.id // comparing identical objects
    }
    
    // unique ID for memory tracking with hash values
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// UIViewControllerRepresentable = "wrapper"; so UIKit's DataScannerViewController can be packaged and SwiftUI can use it.
struct ScannerView: UIViewControllerRepresentable {
    // tap in the UIKit code = pass DishItem back UP to SwiftUI ContentView.
    var onDishTapped: (DishItem) -> Void
    
    // setup
    func makeUIViewController(context: Context) -> DataScannerViewController {
        // initialize built-in Live Text camera scanner
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text(languages: ["id", "th", "vi", "en"])],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: false // we draw our own custom boxes
        )
        
        // send all scanner's detected text to the Coordinator class
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        
        // gesture recognizer to listen for user taps anywhere on the camera screen
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scanner.view.addGestureRecognizer(tap)
        
        try? scanner.startScanning()
        return scanner
    }
    
    // if SwiftUI state changes
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
        func makeCoordinator() -> Coordinator {
            Coordinator(onDishTapped: onDishTapped)
        }
        
        // listens to the delegate callbacks from the UIKit scanner.
        class Coordinator: NSObject, DataScannerViewControllerDelegate {
            
            var onDishTapped: (DishItem) -> Void
            weak var scanner: DataScannerViewController?
            var currentDishes: [DishItem] = [] // temporary memory
            private var lastRenderTime: Date = .distantPast // how fast the boxes redraw
            
            init(onDishTapped: @escaping (DishItem) -> Void) {
                self.onDishTapped = onDishTapped
            }
            
            // every time the user taps the screen
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard let scanner = scanner else { return }
                
                // exact X/Y coordinate of the finger tap
                let tapPoint = gesture.location(in: scanner.overlayContainerView)
                
                // Loops through our known 'currentDishes'. If the finger tap falls inside
                // the CGRect frame of a dish, we have a match!
                if let tapped = currentDishes.first(where: { $0.frame.contains(tapPoint) }) {
                    print("✅ Tapped: \(tapped.name)")
                    // Move back to the main UI thread to trigger the navigation
                    DispatchQueue.main.async {
                        self.onDishTapped(tapped)
                    }
                } else {
                    print("❌ Tap at \(tapPoint) — no dish found")
                }
            }
            
            // callback: VisionKit found new text
            func dataScanner(_ dataScanner: DataScannerViewController,
                             didAdd addedItems: [RecognizedItem],
                             allItems: [RecognizedItem]) {
                throttledRender(allItems, in: dataScanner)
            }
            
            // callback: VisionKit updated the position of text it was tracking
            func dataScanner(_ dataScanner: DataScannerViewController,
                             didUpdate updatedItems: [RecognizedItem],
                             allItems: [RecognizedItem]) {
                
                // clear boxes
                if allItems.isEmpty {
                    DispatchQueue.main.async {
                        dataScanner.overlayContainerView.subviews.forEach { $0.removeFromSuperview() }
                        self.currentDishes = []
                    }
                    return
                }
                throttledRender(allItems, in: dataScanner)
            }
            
            // VisionKit updates 60 times a second. This draws every 0.3 seconds.
            func throttledRender(_ items: [RecognizedItem], in scanner: DataScannerViewController) {
                let now = Date()
                guard now.timeIntervalSince(lastRenderTime) > 0.3 else { return }
                lastRenderTime = now
                renderOverlays(for: items, in: scanner)
            }
            
            // raw VisionKit text blocks into drawn UI boxes
            func renderOverlays(for items: [RecognizedItem], in scanner: DataScannerViewController) {
                var newDishes: [DishItem] = []
                
                for item in items {
                    // text only
                    guard case .text(let text) = item else { continue }
                    
                    // outer perimeter of the detected text block
                    let bounds = text.bounds
                    let minX = min(bounds.topLeft.x, bounds.bottomLeft.x)
                    let maxX = max(bounds.topRight.x, bounds.bottomRight.x)
                    let minY = min(bounds.topLeft.y, bounds.topRight.y)
                    let maxY = max(bounds.bottomLeft.y, bounds.bottomRight.y)
                    let blobFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                    
                    // splitting paragraphs into lines and filtering out bad data
                    let lines = text.transcript
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { isValidDishName($0) }
                    
                    guard !lines.isEmpty else { continue }
                    
                    // divide the big bounding box = smaller horizontal slices based on the number of lines
                    let lineHeight = blobFrame.height / CGFloat(lines.count)
                    
                    for (index, dishName) in lines.enumerated() {
                        let lineFrame = CGRect(
                            x: blobFrame.origin.x,
                            y: blobFrame.origin.y + (lineHeight * CGFloat(index)),
                            width: blobFrame.width,
                            height: lineHeight - 2
                        )
                        
                        let category = stableCategory(for: dishName)
                        newDishes.append(DishItem(name: dishName, frame: lineFrame, category: category))
                    }
                }
                
                // Drawing UI MUST happen on the Main Thread, or the app will crash
                DispatchQueue.main.async {
                    self.currentDishes = newDishes
                    
                    // clear out prev boxes
                    scanner.overlayContainerView.subviews.forEach { $0.removeFromSuperview() }
                    
                    // to draw over the camera
                    for dish in newDishes {
                        let box = UIView(frame: dish.frame)
                        box.layer.borderColor = dish.category.uiColor.cgColor
                        box.layer.borderWidth = 2.0
                        box.layer.cornerRadius = 4
                        // no more physically blocking the tap gesture underneath it
                        box.isUserInteractionEnabled = false
                        
                        let textLabel = UILabel(frame: box.bounds)
                        textLabel.text = dish.name
                        textLabel.textColor = .white
                        textLabel.font = UIFont.boldSystemFont(ofSize: 14)
                        textLabel.textAlignment = .center
                        textLabel.adjustsFontSizeToFitWidth = true // automatically shrinks long text to fit the box
                        
                        textLabel.backgroundColor = dish.category.uiColor.withAlphaComponent(0.85)
                        textLabel.layer.cornerRadius = 2
                        textLabel.clipsToBounds = true
                        
                        box.addSubview(textLabel) // put the text inside the box
                        scanner.overlayContainerView.addSubview(box) // put the box on the screen
                    }
                }
            }
            
            func stableCategory(for name: String) -> DishCategory {
                let allCategories: [DishCategory] = [.safe, .recommended, .caution, .unsafe]
                let index = abs(name.hashValue) % allCategories.count
                return allCategories[index]
            }
            
            func isValidDishName(_ text: String) -> Bool {
                let t = text.trimmingCharacters(in: .whitespaces)
                if t.count < 4 { return false } // short random letters
                if t.contains("Rp") { return false } // prices
                if t.contains("@") { return false } // social media handles
                if t.contains("http") { return false } // websites
                if t.hasPrefix("*") { return false } // footnotes
                if t.lowercased().contains("email") { return false }
                if t.lowercased().contains("instagram") { return false }
                if t.lowercased().contains("alamat") { return false } // addresses
                if t.contains(":") { return false } // time or ratios
                if t.first?.isNumber == true { return false } // quantities like "1. Nasi"
                if t.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) { return false } // pure numbers
                return true
            }
        }
    }
