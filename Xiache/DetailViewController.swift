//
//  DetailViewController.swift
//  Xiache
//
//  Created by 杜标 on 2017/12/26.
//  Copyright © 2017年 weakup. All rights reserved.
//

import Foundation
import UIKit

protocol DetailChangeCallback {
    func getNextDetail() -> (color: UIColor, index: Int)!
    func getPreviousDetail() ->(color: UIColor, index: Int)!
    func updateDetailIndex(index: Int);
    func dismissDetailViewController()
}

class DetailViewController : TransitableViewController {
    var indexLabel = UILabel()
    var headView = UIView()
    var nextButton = UIButton()
    var previousButton = UIButton()
    var scrollView = UIScrollView()
    var detailCallback: DetailChangeCallback!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(scrollView)
        scrollView.addSubview(headView)
        scrollView.frame = self.view.bounds
        headView.frame = self.view.bounds
        headView.frame.size.height = headView.frame.size.height / 2
        headView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        self.view.insetsLayoutMarginsFromSafeArea = false
//        scrollView.insetsLayoutMarginsFromSafeArea = false
//        headView.insetsLayoutMarginsFromSafeArea = false
//
//        print("self.view", self.view.safeAreaInsets, self.view.insetsLayoutMarginsFromSafeArea)
//        print("scrollView", scrollView.safeAreaInsets, scrollView.insetsLayoutMarginsFromSafeArea)
//        print("headView", headView.safeAreaInsets, headView.insetsLayoutMarginsFromSafeArea)
        
        scrollView.contentInsetAdjustmentBehavior = .never
        
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height * 2)
        var scrollSize = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scroll]|", options: .directionMask, metrics: nil, views: ["scroll": scrollView])
        scrollSize.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[scroll]|", options: .directionMask, metrics: nil, views: ["scroll": scrollView]))
        self.view.addConstraints(scrollSize)
        
        headView.addSubview(indexLabel)
        headView.addSubview(nextButton)
        headView.addSubview(previousButton)
        
        indexLabel.textAlignment = .center
        indexLabel.font = UIFont(name: UIFont.familyNames[1], size: 100)
        indexLabel.textColor = UIColor.white
        indexLabel.sizeToFit()
        indexLabel.backgroundColor = UIColor.black
        
        nextButton.setTitle("Next", for: UIControlState.normal)
        previousButton.setTitle("Previous", for: UIControlState.normal)
        
        let height = NSLayoutConstraint(item: indexLabel, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: 100)
        let width = NSLayoutConstraint(item: indexLabel, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: 100)
        let centerX = NSLayoutConstraint(item: indexLabel, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: headView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: indexLabel, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: headView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        indexLabel.addConstraints([height, width])
        headView.addConstraints([centerX, centerY])
        
        let nextRight = NSLayoutConstraint.constraints(withVisualFormat: "H:[btn]-100-|", options: .directionMask, metrics: nil, views: ["btn": nextButton])
        let nextBottom = NSLayoutConstraint.constraints(withVisualFormat: "V:[btn]-30-|", options: .directionMask, metrics: nil, views: ["btn": nextButton])
        headView.addConstraints(nextRight)
        headView.addConstraints(nextBottom)
        
        let previousLeft = NSLayoutConstraint.constraints(withVisualFormat: "H:|-100-[btn]", options: .directionMask, metrics: nil, views: ["btn": previousButton])
        let previousBottom = NSLayoutConstraint.constraints(withVisualFormat: "V:[btn]-30-|", options: .directionMask, metrics: nil, views: ["btn": previousButton])
        headView.addConstraints(previousLeft)
        headView.addConstraints(previousBottom)
        
        indexLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onLabelClick(recognizer:))))
        indexLabel.isUserInteractionEnabled = true
        
        nextButton.addTarget(self, action: #selector(self.showNext(_:)), for: UIControlEvents.touchUpInside)
        previousButton.addTarget(self, action: #selector(self.showPrevious(_:)), for: UIControlEvents.touchUpInside)
    }
    func show(detail: (color: UIColor, index: Int)) {
        print("color is \(detail.color) index is \(detail.index)")
        headView.backgroundColor = detail.color
        indexLabel.text = "\(detail.index)"
        self.view.backgroundColor = UIColor.white
    }
    
    
    @objc func showNext(_: Any?) {
        print("Show next")
        guard let detail = self.detailCallback.getNextDetail() else {
            return
        }
        let snap = getSnapImage(ofView: self.view)
        show(detail: detail)
        let snapNew = getSnapImage(ofView: self.view)
        
        
        let oldSnapView = UIImageView(image: snap)
        let newSnapView = UIImageView(image: snapNew)
        self.view.superview?.addSubview(oldSnapView)
        self.view.superview?.addSubview(newSnapView)
        self.view.superview?.sendSubview(toBack: self.view)
        self.view.isHidden = true
        self.detailCallback.updateDetailIndex(index: detail.index)
        self.moveAnimate(snap: oldSnapView, snapNew: newSnapView, move: .FromRight, atBaseFrame: self.view.frame) {
            self.view.isHidden = false
            oldSnapView.removeFromSuperview()
            newSnapView.removeFromSuperview()
        }
    }
    @objc func showPrevious(_: Any?) {
        print("Show previous")
        guard let detail = self.detailCallback.getPreviousDetail() else {
            return
        }
        let snap = getSnapImage(ofView: self.view)
        show(detail: detail)
        let snapNew = getSnapImage(ofView: self.view)
        
        let oldSnapView = UIImageView(image: snap)
        let newSnapView = UIImageView(image: snapNew)
        self.view.superview?.addSubview(oldSnapView)
        self.view.superview?.addSubview(newSnapView)
        self.view.superview?.sendSubview(toBack: self.view)
        self.view.isHidden = true
        self.detailCallback.updateDetailIndex(index: detail.index)
        self.moveAnimate(snap: oldSnapView, snapNew: newSnapView, move: .FromLeft, atBaseFrame: self.view.frame) {
            self.view.isHidden = false
            oldSnapView.removeFromSuperview()
            newSnapView.removeFromSuperview()
        }
    }
    enum MoveFrom {
        case FromRight
        case FromLeft
    }
    func moveAnimate(snap: UIImageView, snapNew: UIImageView, move moveFrom: MoveFrom, atBaseFrame: CGRect, completion completionBlock: @escaping ()->()) {
        let oFrame = atBaseFrame
        let smallCenterFrame = scaleRectCenter(rect: oFrame, scale: 0.8);
        let smallRightFrame = smallCenterFrame.offsetBy(dx: smallCenterFrame.width, dy: 0)
        let smallLeftFrame = smallCenterFrame.offsetBy(dx: -smallCenterFrame.width, dy: 0)
        
//        let fromFrame = moveFrom == .FromLeft ? smallLeftFrame : smallRightFrame
//        let toFrame = moveFrom == .FromLeft ? smallRightFrame : smallLeftFrame
        
        let fromBigOffset = (moveFrom == .FromLeft ? -1 : 1) * oFrame.width
        let fromBigFrame = oFrame.offsetBy(dx: fromBigOffset, dy: 0)
        let toBigFrame = oFrame.offsetBy(dx: -fromBigOffset, dy: 0)
        
        let fromSmallFrame = moveFrom == .FromLeft ? smallLeftFrame : smallRightFrame
        let toSmallFrame = moveFrom == .FromLeft ? smallRightFrame : smallLeftFrame
        
        snap.frame = oFrame
        snapNew.frame = fromBigFrame
        UIView.animate(withDuration: 0.2, animations: {
            snap.frame = smallCenterFrame
            snapNew.frame = fromSmallFrame
        }) { (f) in
            UIView.animate(withDuration: 0.2, animations: {
                snap.frame = toSmallFrame
                snapNew.frame = smallCenterFrame
            }, completion: { (f) in
                UIView.animate(withDuration: 0.2, animations: {
                    snap.frame = toBigFrame
                    snapNew.frame = oFrame
                }, completion: { (f) in
                    completionBlock()
                })
            })
        }
    }
    
    
    @objc func onLabelClick(recognizer: UITapGestureRecognizer) {
        print("click dismiss")
        detailCallback?.dismissDetailViewController()
    }
    
    func scaleRectCenter(rect: CGRect, scale: CGFloat) -> CGRect {
        let nWidth = rect.width * scale
        let nHeight = rect.height * scale
        let offsetX = (rect.width - nWidth) / 2
        let offsetY = (rect.height - nHeight) / 2
        var origin = rect.origin
        origin.x = origin.x + offsetX
        origin.y = origin.y + offsetY
        return CGRect(origin: origin , size: CGSize(width: nWidth, height: nHeight))
    }
}

