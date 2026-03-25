import UIKit

// MARK: - 1. Data Models
struct TouchPoint {
    let location: CGPoint
    let pressure: CGFloat
    let timestamp: TimeInterval
}

enum ToolType {
    case pen
    case highlighter
    case eraser
}

struct Stroke {
    var points: [TouchPoint]
    var color: UIColor
    var brushWidth: CGFloat
    var tool: ToolType
}

// MARK: - 2. The Drawing Engine
class CanvasView: UIView {
    var finishedStrokes: [Stroke] = []
    var currentStroke: Stroke?
    var backgroundImage: UIImage? // The "Dry Ink" buffer
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) { 
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.isMultipleTouchEnabled = false
    }
    
    // MARK: Touch Tracking
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let newPoint = TouchPoint(location: touch.location(in: self), pressure: touch.force, timestamp: touch.timestamp)
        currentStroke = Stroke(points: [newPoint], color: .black, brushWidth: 3.0, tool: .pen)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, var stroke = currentStroke else { return }
        let newPoint = TouchPoint(location: touch.location(in: self), pressure: touch.force, timestamp: touch.timestamp)
        stroke.points.append(newPoint)
        currentStroke = stroke
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, var stroke = currentStroke else { return }
        let finalPoint = TouchPoint(location: touch.location(in: self), pressure: touch.force, timestamp: touch.timestamp)
        stroke.points.append(finalPoint)
        finishedStrokes.append(stroke)
        
        stampStrokeOntoBackground(stroke: stroke) // Flatten the ink!
        currentStroke = nil
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentStroke = nil
        setNeedsDisplay()
    }
    
    // MARK: Rendering & Math
    private func stampStrokeOntoBackground(stroke: Stroke) {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        backgroundImage = renderer.image { _ in
            backgroundImage?.draw(in: bounds)
            render(stroke: stroke)
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: rect) // Draw the dry ink instantly
        
        if let currentStroke = currentStroke {
            render(stroke: currentStroke) // Draw the wet ink
        }
    }
    
    private func render(stroke: Stroke) {
        guard stroke.points.count > 0 else { return }
        let path = UIBezierPath()
        path.lineWidth = stroke.brushWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        path.move(to: stroke.points[0].location)
        
        if stroke.points.count == 2 {
            path.addLine(to: stroke.points[1].location)
        } else if stroke.points.count > 2 {
            for i in 1 ..< stroke.points.count - 1 {
                let p0 = stroke.points[i - 1].location
                let p1 = stroke.points[i].location
                let midPoint = CGPoint(x: (p0.x + p1.x) / 2.0, y: (p0.y + p1.y) / 2.0)
                
                if i == 1 {
                    path.addLine(to: midPoint)
                } else {
                    path.addQuadCurve(to: midPoint, controlPoint: p0)
                }
            }
            guard let lastPoint = stroke.points.last?.location else { return }
            path.addLine(to: lastPoint)
        }
        stroke.color.setStroke()
        path.stroke()
    }
}