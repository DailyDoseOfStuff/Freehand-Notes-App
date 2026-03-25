//for SwiftPlaygrounds
import SwiftUI

// This wrapper translates our UIKit engine into a SwiftUI view
struct CanvasViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> CanvasView {
        let canvas = CanvasView()
        return canvas
    }
    
    func updateUIView(_ uiView: CanvasView, context: Context) {
        // We don't need to update anything dynamically right now
    }
}

// This is the main screen of your Playgrounds App
struct ContentView: View {
    var body: some View {
        CanvasViewWrapper()
            .ignoresSafeArea() // Stretches the canvas edge-to-edge
    }
}