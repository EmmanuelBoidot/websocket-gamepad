//
//  MFLSwiftJoystick.swift
//  JoyStickDemo
//
//  Created by TJ Fallon on 2/19/15.
//  Copyright (c) 2015 Foley. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol MFLSwiftJoystickDelegate
{
    func joyStickDidUpdate(_ movement:CGPoint)
}

@objc open class MFLSwiftJoystickImplementation : UIView
{
    /*
    *   Below here be demons, and they're swift.
    */
    @IBOutlet open weak var delegate: MFLSwiftJoystickDelegate?;

    var smallestPossible: CGFloat               = 0.09;
    var moveViscosity: CGFloat                  = 4;
    var defaultPoint: CGPoint                   = CGPoint.zero;

    var bgImageView: UIImageView!;
    var thumbImageView: UIImageView!;
    var handle: UIView!;

    var isTouching                              = false;

    required public init(coder: NSCoder) {
        super.init(coder: coder)!
        sharedInit();
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    open func setMoveViscosityWithMinimum(_ viscosity: CGFloat, minimum: CGFloat) {
        moveViscosity = viscosity
        smallestPossible = minimum
    }

    open func setupWithThumbAndBackgroundImages(_ thumbImage: UIImage, bgImage: UIImage) {
        thumbImageView.image = thumbImage;
        bgImageView.image = bgImage;
    }

    func sharedInit() {
        roundViewToDiameter(self, newSize:bounds.size.width)

        bgImageView = UIImageView(frame:CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height));
        roundViewToDiameter(bgImageView, newSize:bgImageView.bounds.size.width)
        addSubview(bgImageView)


        makeHandle()
        animate()
        notifyDelegate()
    }

    func makeHandle() {
        handle = UIView(frame: CGRect(x: 0, y: 0, width: 61, height: 61))
        handle.center = CGPoint(x: bounds.size.width / 2,
            y: bounds.size.height/2)

        defaultPoint = handle.center
        roundViewToDiameter(handle, newSize: handle.bounds.width)
        self.addSubview(handle)

        thumbImageView = UIImageView(frame:handle.frame)
        self.addSubview(self.thumbImageView)
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.alpha = 1;
        }) 
        self.touchesMoved(touches, with: event)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let myTouch: UITouch = touches.first as? UITouch! {
            var currentPos = myTouch.location(in: self)

            let selfCenter = CGPoint(x: (bounds.origin.x + bounds.size.width/2),
                y: (bounds.origin.y + bounds.size.height/2))
            let selfRadius = (bounds.size.width / 2) - 34;

            if (distanceBetweenTwoPoints(currentPos, point2: selfCenter) > selfRadius) {
                let vX = currentPos.x - selfCenter.x;
                let vY = currentPos.y - selfCenter.y;
                let magV = sqrt(vX*vX + vY*vY);
                currentPos.x = selfCenter.x + vX / magV * selfRadius;
                currentPos.y = selfCenter.y + vY / magV * selfRadius;
            }

            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.thumbImageView.center = currentPos;
            }) 

            handle.center = currentPos;
            isTouching = true
            notifyDelegate();
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.alpha = 0.6;
        }) 
        delegate?.joyStickDidUpdate(CGPoint.zero)
        isTouching = false
    }

    func isPointInCircleOfRadiusWithCenter(_ point: CGPoint, center: CGPoint, radius: CGFloat) -> Bool {
        let deltaX = Float((point.x-center.x))
        let xSquared = powf(deltaX, 2);

        let deltaY = Float((point.y-center.y))
        let ySquared = powf(deltaY, 2);

//        let xPointPow = center.x;

        return ((xSquared + ySquared) < powf(Float(radius), 2.0));
    }

    func animate() {

        if (!isTouching) {
            //move the handle back to the default position
            var newX:Float = Float(handle.center.x)
            var newY:Float = Float(handle.center.y)
            let dx = fabsf(newX - Float(defaultPoint.x))
            let dy = fabsf(newY - Float(defaultPoint.y))

            let floatMV = Float(moveViscosity)
            if (handle.center.x > defaultPoint.x) {
                newX = newX - dx/floatMV
            } else if (handle.center.x < defaultPoint.x) {
                newX = newX + dx/floatMV
            }

            if (handle.center.y > defaultPoint.y) {
                newY = newY - dy/Float(moveViscosity)
            } else if (handle.center.y < defaultPoint.y) {
                newY = newY + dy/Float(moveViscosity)
            }

            if (Float(fabsf(dx/floatMV)) < Float(smallestPossible) &&
                Float(fabsf(dy/floatMV)) < Float(smallestPossible))
            {
                newX = Float(defaultPoint.x)
                newY = Float(defaultPoint.y)
            }

            handle.center = CGPoint(x: CGFloat(newX), y: CGFloat(newY))
            thumbImageView.center = handle.center
        }
        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(1.0/45.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) { () -> Void in
            self.animate()
        }
    }

    func notifyDelegate() {
        if (isTouching) {
            let positionX = (handle.frame.minX / handle.frame.width - 0.55) * 2.0;
            let positionY = (handle.frame.minY / handle.frame.height - 0.55) * 2.0;
            let degreeOfPosition = CGPoint(x: positionX, y: positionY)
            [delegate?.joyStickDidUpdate(degreeOfPosition)];
        }
    }
    
//    public func getAngle() -> Float {
//        let newX:Float = Float(handle.center.x)
//        let newY:Float = Float(handle.center.y)
//        let dx = fabsf(newX - Float(defaultPoint.x))
//        let dy = fabsf(newY - Float(defaultPoint.y))
//        if (dx < Float(smallestPossible)){
//            return 0.0;
//        }
//        return Float(atan2(dx,dy));
//    }
//    
//    public func getRadius() -> Float {
//        let newX:Float = Float(handle.center.x)
//        let newY:Float = Float(handle.center.y)
//        let dx = fabsf(newX - Float(defaultPoint.x))
//        let dy = fabsf(newY - Float(defaultPoint.y))
//        return Float(sqrt(dx*dx+dy*dy));
//    }

    func roundViewToDiameter(_ roundedView: UIView, newSize:CGFloat) {
        let saveCenter = roundedView.center;
        let newFrame = CGRect(x:roundedView.frame.origin.x,
            y:roundedView.frame.origin.y,
            width:newSize,
            height:newSize)
        roundedView.frame = newFrame;
        roundedView.layer.cornerRadius = newSize / 2.0
        roundedView.center = saveCenter
    }
    
    func distanceBetweenTwoPoints(_ point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        let distance = sqrt((dx * dx) + (dy * dy));
        return distance;
    }
    
}
