//
//  MyButton.swift
//  CustomButton
//
//  Created by Panucci, Julian R on 3/22/17.
//  Copyright © 2017 Panucci, Julian R. All rights reserved.
//

import UIKit

@IBDesignable
class SwitchButton: UIView {
    

    //MARK: Inspectables
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var shadow: CGFloat = 0.0
    @IBInspectable open var duration: Double = 0.5
    @IBInspectable var onTintColor: UIColor = .blue
    @IBInspectable fileprivate var isOn = false
    
    fileprivate var shape: CAShapeLayer! = CAShapeLayer()
    
    private var rectShape = CAShapeLayer()
    private var startShape: CGPath!
    private var endShape: CGPath!
    private var button: UIButton!
    
    open var animationDidStartClosure = {(onAnimation: Bool) -> Void in }
    open var animationDidStopClosure  = {(onAnimation: Bool, finished: Bool) -> Void in }
    open var onClick = { () -> Void in }
    open var isEnabled: Bool = true
    

    override func draw(_ rect: CGRect) {
        layer.cornerRadius = cornerRadius
        commonInit()
    }
    
    init(frame: CGRect ,color: UIColor) {
        super.init(frame: frame)
        onTintColor = color
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: Helpers
    fileprivate func commonInit() {
        
        button = UIButton(frame: layer.bounds)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(SwitchButton.buttonAction), for: .touchUpInside)
        button.addTarget(self, action: #selector(SwitchButton.unShrink), for: .touchCancel)
        button.addTarget(self, action: #selector(SwitchButton.unShrink), for: .touchDragExit)
        button.addTarget(self, action: #selector(SwitchButton.shrink), for: .touchDown)
        self.addSubview(button)
        
        let rectBounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        startShape = UIBezierPath(roundedRect: rectBounds, cornerRadius: 50).cgPath
        
        let height = layer.bounds.height * 3
        let width = height
        
        let x = height / -2.4 - 20
        let y = x
        
        let radius = CGFloat(height / 2.0)
        
        
        endShape = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: radius).cgPath
        
        rectShape.path = startShape
        rectShape.fillColor = onTintColor.cgColor
        rectShape.bounds = rectBounds
        rectShape.position = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        rectShape.cornerRadius = rectBounds.width / 2
        
        
        layer.insertSublayer(rectShape, at: 0)
        layer.masksToBounds = true

    }
    

    // MARK: - Animations
    fileprivate func animateButton(toValue to: CGPath) {
        
        let animation = CABasicAnimation(keyPath: "path")
        
        animation.toValue               = to
        animation.fromValue = rectShape.path
        animation.timingFunction        = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.isRemovedOnCompletion = false
        animation.fillMode              = kCAFillModeBoth
        animation.duration              = duration
        animation.delegate              = self
        
        rectShape.add(animation, forKey: animation.keyPath)
        rectShape.path = to
    }
    
    func turnOn() {
        if !isOn {
            //If button is off, turn it on
            animateButton(toValue: endShape)
            isOn = !isOn
        }
    }
    
    func turnOff() {
        if isOn {
            animateButton(toValue: startShape)
            isOn = !isOn
        }
    }
    
    func switchState() {
        isOn ? turnOff() : turnOn()
    }
    
    internal func buttonAction()
    {
        if isEnabled {
            onClick()
        }
        
        unShrink()
    }
    
    internal func shrink()
    {
        UIView.animate(withDuration: 0.5) {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
    }

    internal func unShrink()
    {
        UIView.animate(withDuration: 0.5) {
            self.transform = CGAffineTransform.identity
        }
    }
}


extension SwitchButton: CAAnimationDelegate {
    internal func animationDidStart(_ anim: CAAnimation) {
        animationDidStartClosure(isOn)
    }
    
    internal func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        animationDidStopClosure(isOn, flag)
    }
}