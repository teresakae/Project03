import SwiftUI
import VisionKit

struct DishItem: Identifiable {
    let id = UUID()
    let name: String
    let frame: CGRect
}

struct ScannerView: UIViewControllerRepresentable {
    
    var onDishTapped: (DishItem) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text(languages: ["id", "th", "vi", "en"])],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        
        // Add tap gesture directly to the scanner view — bypasses overlayContainerView issues
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scanner.view.addGestureRecognizer(tap)
        
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDishTapped: onDishTapped)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        
        var onDishTapped: (DishItem) -> Void
        weak var scanner: DataScannerViewController?
        var currentDishes: [DishItem] = []  // keep track of all rendered dishes + their frames
        private var lastRenderTime: Date = .distantPast
        
        init(onDishTapped: @escaping (DishItem) -> Void) {
            self.onDishTapped = onDishTapped
        }
        
        // MARK: - Tap handler
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scanner = scanner else { return }
            let tapPoint = gesture.location(in: scanner.overlayContainerView)
            
            // Find which dish frame contains the tap point
            if let tapped = currentDishes.first(where: { $0.frame.contains(tapPoint) }) {
                print("✅ Tapped: \(tapped.name)")  // check Xcode console first
                DispatchQueue.main.async {
                    self.onDishTapped(tapped)
                }
            } else {
                print("❌ Tap at \(tapPoint) — no dish found")
            }
        }
        
        // MARK: - Delegate
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            throttledRender(allItems, in: dataScanner)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            throttledRender(allItems, in: dataScanner)
        }
        
        func throttledRender(_ items: [RecognizedItem], in scanner: DataScannerViewController) {
            let now = Date()
            guard now.timeIntervalSince(lastRenderTime) > 0.8 else { return }
            lastRenderTime = now
            renderOverlays(for: items, in: scanner)
        }
        
        // MARK: - Overlay rendering
        func renderOverlays(for items: [RecognizedItem], in scanner: DataScannerViewController) {
            var newDishes: [DishItem] = []
            
            for item in items {
                guard case .text(let text) = item else { continue }
                
                let bounds = text.bounds
                let minX = min(bounds.topLeft.x, bounds.bottomLeft.x)
                let maxX = max(bounds.topRight.x, bounds.bottomRight.x)
                let minY = min(bounds.topLeft.y, bounds.topRight.y)
                let maxY = max(bounds.bottomLeft.y, bounds.bottomRight.y)
                let blobFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                
                let lines = text.transcript
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { isValidDishName($0) }
                
                guard !lines.isEmpty else { continue }
                
                let lineHeight = blobFrame.height / CGFloat(lines.count)
                
                for (index, dishName) in lines.enumerated() {
                    let lineFrame = CGRect(
                        x: blobFrame.origin.x,
                        y: blobFrame.origin.y + (lineHeight * CGFloat(index)),
                        width: blobFrame.width,
                        height: lineHeight - 2
                    )
                    newDishes.append(DishItem(name: dishName, frame: lineFrame))
                }
            }
            
            // Update dishes list and redraw overlays on main thread
            DispatchQueue.main.async {
                self.currentDishes = newDishes
                scanner.overlayContainerView.subviews.forEach { $0.removeFromSuperview() }
                
                for dish in newDishes {
                    let box = UIView(frame: dish.frame)
                    box.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    box.layer.borderColor = UIColor.systemGreen.cgColor
                    box.layer.borderWidth = 1.5
                    box.layer.cornerRadius = 4
                    box.isUserInteractionEnabled = false  // gesture handles taps, not the view
                    scanner.overlayContainerView.addSubview(box)
                }
            }
        }
        
        // MARK: - Filter
        func isValidDishName(_ text: String) -> Bool {
            let t = text.trimmingCharacters(in: .whitespaces)
            if t.count < 4 { return false }
            if t.contains("Rp") { return false }
            if t.contains("@") { return false }
            if t.contains("http") { return false }
            if t.hasPrefix("*") { return false }
            if t.lowercased().contains("email") { return false }
            if t.lowercased().contains("instagram") { return false }
            if t.lowercased().contains("alamat") { return false }
            if t.contains(":") { return false }
            if t.first?.isNumber == true { return false }
            if t.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) { return false }
            return true
        }
    }
}
