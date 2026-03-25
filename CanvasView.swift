import CoreGraphics 
import UIKit


//represents a single point in time during a stroke
struct TouchPoint{
    var location: CGPoint
    var pressure: CGFloat
    var timestamp: TimeInterval
}

//represnets one continuous line (from touch up to down)
struct Stroke {
    var points: [TouchPoint]
    var color: UIColor
    var brushWidth: CGFloat
    var id: UUID = UUID()
}

enum ToolType {
    case pen
    case eraser
    case highlighter
}

class CanvasView: UIView {
   
   //Memory: Stores shit 
   var finished Strokes: [Strokes] = []
   var currentStroke: Stroke? 

   //Mark --init 
   override init(frame:CGRect){
    super.init(frame: frame)
    setupView()
   }

   //Required if ever use Storyboard/Interface builder
   required init?(coder: NSCoder){
    super.init(coder:coder)
    setupView()
   }

   private func setupView(){
    self.backgroundColor = .white
    self.isMultipleTouchEnabled = false //force single-stroke at a time
   }

   // Mark: -- Touch tracking 
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let newPoint = TouchPoint(
            location: touch.location(in: self),
            pressure: touch.force, // Captures Apple Pencil pressure
            timestamp: touch.timestamp
        )
        
        // Start a new stroke with default settings (Black pen, width 3.0)
        currentStroke = Stroke(points: [newPoint], color: .black, brushWidth: 3.0, tool: .pen)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, var stroke = currentStroke else { return }
        
        let newPoint = TouchPoint(
            location: touch.location(in: self),
            pressure: touch.force,
            timestamp: touch.timestamp
        )
        
        stroke.points.append(newPoint)
        currentStroke = stroke
        
        // Tells the view to redraw on the next frame
        setNeedsDisplay() 
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, var stroke = currentStroke else { return }
        
        // Capture the final lift-off point
        let finalPoint = TouchPoint(
            location: touch.location(in: self),
            pressure: touch.force,
            timestamp: touch.timestamp
        )
        stroke.points.append(finalPoint)
        
        finishedStrokes.append(stroke)
        currentStroke = nil
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch> , with event: UIEvent?){
        currentStroke = nil 
        setNeedsDisplay()
    }

    //MARK: - Rendering n Math
    override func draw(_ rect: CGRect){
        //Draw the saved history 
        for stroke in finishedStrokes{
            render(stroke: stroke)
        }

        //DDraw the active line
        if let currentStroke - currentStroke {
            render(stroke: currentStroke)
        }
    }

    private func render(stroke: Stroke){
        guard stroke.points.count > 0 else {return} 

        let path = UIBezierPath()
        path.lineWidth = stroke.brushWidth 
        path.lineCapStyle = .round 
        path.lineJoinStyle = .round 

        path.move(to: stroke.points[0].location)

        if stroke.points.count == 2{
            //Draw a line between the two points if only 2 pts 
            path.addLine(to: stroke.points[1].location)
        } else if stroke.points.count > 2 {
            //Smothing the line out 
            for i in 1 ..< stroke.points.count - 1 {
                let p0 = stroke.points[i-1].location
                let p1 = stroke.points[i].location

                let mdpt = calculateMidPoint(p1: p0, p2: p1)

                if i == 1 {
                    path.addLine(to: midPoint)
                } else {
                    path.addQuadCurve(to: mdpt, controlPoint: p0)
                }
            }
            
            //connect very last pt 
            guard let lastPoint = stroke.points.last?.location else {return}
            path.addLine(to: lastPoint)
        }
        stroke.color.setStroke()
        path.stroke()
    }

    private func calculateMidPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2
        )
    }
}