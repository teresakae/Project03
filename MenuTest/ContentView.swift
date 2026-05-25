import SwiftUI
import VisionKit

// struct to hold the text with a unique ID
struct DetectedText: Identifiable {
    let id = UUID()
    let text: String
}

struct ContentView: View {
    @State private var detectedTexts: [DetectedText] = []
    @State private var isScannerSupported = false

    var body: some View {
        VStack(spacing: 0) {
            if isScannerSupported {
                ScannerView { tappedDish in
                    // 1. Get the raw string from the tapped button
                    var cleanedText = tappedDish.name.trimmingCharacters(in: .whitespaces)
                    
                    // 2. Strip leading numbering like "1. " or "12. "
                    if let range = cleanedText.range(of: #"^\d+\.\s*"#, options: .regularExpression) {
                        cleanedText = String(cleanedText[range.upperBound...])
                    }
                    
                    // 3. Strip inline prices that got grouped (e.g. "Nasi Goreng\n15.000")
                    cleanedText = cleanedText.components(separatedBy: "\n")
                        .filter { line in
                            let l = line.trimmingCharacters(in: .whitespaces)
                            // drop lines that are purely numeric (15.000, 14.000)
                            return !l.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," })
                        }
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespaces)
                    
                    // 4. Final safety check: if nothing is left after cleanup, ignore the tap
                    if cleanedText.isEmpty || cleanedText.count < 4 { return }
                    
                    // 5. Create your object and update the UI
                    let newDetectedText = DetectedText(text: cleanedText)
                    
                    DispatchQueue.main.async {
                        self.detectedTexts.append(newDetectedText)
                    }
                }
                .frame(height: 400)
                .cornerRadius(12)
                .padding()
                .frame(height: 400)
                .cornerRadius(12)
                .padding()
            } else {
                Text("Scanner not supported on this device")
                    .foregroundColor(.red)
                    .padding()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Text (\(detectedTexts.count) items)")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)

                    ForEach(detectedTexts) { item in
                        Text("• \(item.text)")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            isScannerSupported = DataScannerViewController.isSupported
                               && DataScannerViewController.isAvailable
        }
    }
}
