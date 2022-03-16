// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

protocol SelectionViewDelegate : AnyObject {
    func selectViewDidSelectDidAction(_ view : SelectionView)
}

protocol NavSelectionViewDelegate : AnyObject {
    func selectViewDidSelectDidAction(_ view : NavSelectionView)
}

/**
Used as an overlay on selected cells
*/
@IBDesignable final class SelectionView: UIView {
    weak var delegate : SelectionViewDelegate?
    
    var selectionString: String = "" {
        didSet {
            if selectionString != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    var selected : Bool = false {
        didSet {
            if selected != oldValue {
                if !selected {
                    selectionString = ""
                }else{
                    setNeedsDisplay()
                }
            }
        }
    }
    
    var offset = CGFloat(5.0) {
        didSet {
            setNeedsDisplay();
        }
    }
    
    var circleRadius = CGFloat(25.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    let settings = DataCenter.shared.settings

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()
        let shadow2Offset = CGSize(width: 0.1, height: -0.1);
        let shadow2BlurRadius: CGFloat = 2.5;
        let checkmarkFrame = CGRect(x: bounds.width - circleRadius - offset, y: offset, width: circleRadius, height: circleRadius);
        let group = CGRect(x: checkmarkFrame.minX + 3, y: checkmarkFrame.minY + 3, width: checkmarkFrame.width - 6, height: checkmarkFrame.height - 6)
        
        //// CheckedOval Drawing
        let checkedArea = CGRect(x: group.minX + floor(group.width * 0.0 + 0.5), y: group.minY + floor(group.height * 0.0 + 0.5), width: floor(group.width * 1.0 + 0.5) - floor(group.width * 0.0 + 0.5), height: floor(group.height * 1.0 + 0.5) - floor(group.height * 0.0 + 0.5))
        let checkedOvalPath = UIBezierPath(ovalIn: checkedArea)
        context?.saveGState()
        context?.setShadow(offset: shadow2Offset, blur: shadow2BlurRadius, color: UIColor.clear.cgColor)

        selected ? settings.selectionFillColor.setFill() : UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).setFill()
        checkedOvalPath.fill()
        context?.restoreGState()
        
        selected ? settings.selectionStrokeColor.setStroke() : UIColor.white.setStroke()
        checkedOvalPath.lineWidth = 1
        checkedOvalPath.stroke()
        
        context?.setFillColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor)
        
        //// Check mark for single assets
        if (settings.maxNumberOfSelections == 1 && selected) {
            context?.setStrokeColor(UIColor.white.cgColor)
            let checkPath = UIBezierPath()
            let center = CGPoint(x: checkedArea.midX, y: checkedArea.midY)
            checkPath.move(to: CGPoint(x: center.x - 5, y: center.y))
            checkPath.addLine(to: CGPoint(x: center.x - 1, y: center.y + 3.5))
            checkPath.addLine(to: CGPoint(x: center.x + 4.5, y: center.y - 3))
            checkPath.stroke()
            return;
        }
        
        //// Bezier Drawing (Picture Number)
        let size = selectionString.size(withAttributes: settings.selectionTextAttributes)
        selectionString.draw(in: CGRect(x: checkmarkFrame.midX - size.width / 2.0, y: checkmarkFrame.midY - size.height / 2.0, width: size.width, height: size.height), withAttributes: settings.selectionTextAttributes)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate != nil {
            self.delegate?.selectViewDidSelectDidAction(self)
        }else {
            super.touchesEnded(touches, with: event)
        }
    }
}


class NavSelectionView: UIView{
    weak var delegate : NavSelectionViewDelegate?
    var selectionString: String = "" {
        didSet {
            if selectionString != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    var selected : Bool = false {
        didSet {
            if selected != oldValue {
                switchImage!.isHighlighted = selected
            }
        }
    }
    
    let settings = DataCenter.shared.settings

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var switchImage:UIImageView?
    func setupUI(){
        let title = UILabel(frame: CGRect(x: self.wm_width-34, y: 1, width: 34, height: 50))
        title.text = "选择"
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = UIColor.white
        title.textAlignment = NSTextAlignment.right
        self.addSubview(title);
        
        switchImage = UIImageView(frame: CGRect(x: title.wm_x-23, y: 0, width: 23, height: 50))
        switchImage?.image = UIImage(named: "nav_res_uncheck")
        switchImage?.highlightedImage = UIImage(named: "nav_res_checked")
        switchImage?.contentMode = UIView.ContentMode.scaleAspectFit
        self.addSubview(switchImage!)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if delegate != nil {
            self.delegate?.selectViewDidSelectDidAction(self)
        }else {
            super.touchesEnded(touches, with: event)
        }
    }
}
