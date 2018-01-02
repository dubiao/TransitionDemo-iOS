//
//  DetailInteractiveTransition.swift
//  Xiache
//
//  Created by 杜标 on 2017/12/26.
//  Copyright © 2017年 weakup. All rights reserved.
//

import Foundation
import UIKit

protocol TransitionDelegate {
    func initViewController(fromView: UIView, andPresentAnimate present: (_ persenter: UIViewController, _ persenting: TransitableViewController)->() ) -> TransitableViewController! ;
    func frameInScreen(forView view: UIView) -> CGRect
}

class TransitableViewController: UIViewController {
    var dismissTransition: DetailInteractiveTransition.Dismiss!
    
    func getSnapImage(ofView view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 0)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

class DetailInteractiveTransition : UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate {
    var delegate: TransitionDelegate!
    var keyView: UIView! {
        didSet {
            self.originFrameOfKeyView = keyView?.frame
        }
    }
    var dismiss: Dismiss!
    var isDraggingUp: Bool!
    var originFrameOfKeyView: CGRect!
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGestureRecognizer.velocity(in: panGestureRecognizer.view)
            let shouldBegin = fabs(velocity.y) > fabs(velocity.x) * 2;
            if shouldBegin {
                self.isDraggingUp = velocity.y < 0
            } else {
                self.isDraggingUp = nil
            }
            return shouldBegin
        } else {
            return false
        }
    }
    
    func bind(toView view: UIView) {
        let panUp = UIPanGestureRecognizer(target: self, action: #selector(self.panUp(recognizer:)))
        panUp.delegate = self
        view.addGestureRecognizer(panUp)
        let click = UITapGestureRecognizer(target: self, action: #selector(self.click(recognizer:)))
        view.addGestureRecognizer(click)
    }
    
    func createDismiss(forViewController vc: TransitableViewController) -> Dismiss {
        vc.dismissTransition = Dismiss()
        vc.dismissTransition.workingVC = vc
        vc.dismissTransition.present = self
        self.dismiss = vc.dismissTransition
        return self.dismiss
    }
    
    @objc func click(recognizer: UITapGestureRecognizer) {
        keyView = recognizer.view
        _ = delegate?.initViewController(fromView: keyView!, andPresentAnimate: { (presenter, presenting) in
            presenting.transitioningDelegate = self
            presenter.present(presenting, animated: true, completion: {
                _ = self.createDismiss(forViewController: presenting)
            })
        })
    }
    
    @objc func panUp(recognizer: UIPanGestureRecognizer) {
        if isDraggingUp == nil {
            return
        }
        let X: CGFloat = 200
        let translation = recognizer.translation(in: recognizer.view?.superview)
        switch recognizer.state {
        case .began:
            keyView = recognizer.view
            if isDraggingUp {
                _ = delegate?.initViewController(fromView: keyView!, andPresentAnimate: { (presenter, presenting) in
                    presenting.transitioningDelegate = self
                    presenter.present(presenting, animated: true, completion: {
                        _ = self.createDismiss(forViewController: presenting)
                    })
                    self.update(0)
                })
            } else {
                
            }
        case .changed:
            if isDraggingUp != (translation.y < 0) {
                if isDraggingUp {
                    print("end")
                    self.update(0)
                    self.cancel()
                } else {
                    print("present")
                    _ = delegate?.initViewController(fromView: keyView!, andPresentAnimate: { (presenter, presenting) in
                        presenting.transitioningDelegate = self
                        presenter.present(presenting, animated: true, completion: {
                            _ = self.createDismiss(forViewController: presenting)
                        })
                    })
                }
                isDraggingUp = !isDraggingUp
                return
            }
            
            print("translation.y to ", translation.y)
            if (translation.y > 0) {
                keyView.frame = self.originFrameOfKeyView.offsetBy(dx: 0, dy: log2(translation.y + 1) * 5)
            } else if translation.y < -X {
                keyView.frame = self.originFrameOfKeyView
                print("finish")
                isDraggingUp = nil
                self.finish()
            } else {
                keyView.frame = self.originFrameOfKeyView
                var fraction = CGFloat((Float(-translation.y))) / X
                fraction = CGFloat(fminf(fmaxf(Float(fraction), 0), 1));
                print("update", fraction * 100)
                self.update(fraction)
            }
        case .ended, .cancelled:
            if !isDraggingUp {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    self.keyView.frame = self.originFrameOfKeyView
                }, completion: nil)
            } else {
            }
            var fraction = CGFloat((Float(-translation.y))) / X
            fraction = CGFloat(fminf(fmaxf(Float(fraction), 0), 1));
            print("translation.y at", translation.y)
            if fraction < 0.25 && recognizer.velocity(in: keyView?.superview).y > -300 {
                self.cancel()
            } else {
                self.finish()
            }
        default:
            break
            
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let d = self.transitionDuration(using: transitionContext);
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! TransitableViewController
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        let image = toVC.getSnapImage(ofView: toView)
        let snap = UIImageView(image: image)
        
        transitionContext.containerView.addSubview(snap)
        let finalFrame = transitionContext.finalFrame(for: toVC)
        snap.frame = self.delegate!.frameInScreen(forView: keyView)
        UIView.animate(withDuration: d, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 10, options: UIViewAnimationOptions.curveLinear, animations: {
            snap.frame = finalFrame
            //                toView.alpha = 1
        }, completion: { (finish) in
            self.keyView.alpha = 1
            transitionContext.containerView.addSubview(toView)
            snap.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func scaleFrame(from: CGRect, toFrame: CGRect, percent: CGFloat) -> CGRect {
        func scaleValue(_ fromValue: CGFloat, _ toValue: CGFloat) -> CGFloat {
            return fromValue + (toValue - fromValue) * percent
        }
        return CGRect(x: scaleValue(from.origin.x, toFrame.origin.x), y: scaleValue(from.origin.y, toFrame.origin.y), width: scaleValue(from.size.width, toFrame.size.width), height: scaleValue(from.size.height, toFrame.size.height))
    }
    
    class Dismiss: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning {
        var present: DetailInteractiveTransition! {
            didSet {
                self.delegate = present?.delegate
            }
        }
        var delegate: TransitionDelegate!
        var workingVC: TransitableViewController!
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.6
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let d = self.transitionDuration(using: transitionContext);
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as! TransitableViewController
            let fromView = UIImageView(image: fromVC.getSnapImage(ofView: fromVC.view))
            transitionContext.containerView.addSubview(fromView)
            transitionContext.containerView.addSubview(toVC.view)
            transitionContext.containerView.sendSubview(toBack: toVC.view)
            fromVC.view.isHidden = true
            
            let toFinalFrame = self.delegate!.frameInScreen(forView: self.present.keyView)
            let toMiddleFrame = toFinalFrame.offsetBy(dx: 0, dy: -toFinalFrame.height / 3)
            
            let keyFinalFrame = self.present.keyView.frame
            self.present.keyView.frame = self.present.keyView.frame.offsetBy(dx: 0, dy: -toFinalFrame.height / 3)
            
            UIView.animate(withDuration: d / 2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations:{
                fromView.frame = toMiddleFrame
                fromView.layoutIfNeeded()
            }) {(f) in
                UIView.animate(withDuration: d / 2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    fromView.frame = toFinalFrame
                    fromView.alpha = 0
                    self.present.keyView.frame = keyFinalFrame
                }, completion: { (finish) in
                    fromView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            }
        }
        
        fileprivate func getPanGesture() -> UIPanGestureRecognizer {
            return UIPanGestureRecognizer(target: self, action: #selector(self.panDown(recognizer:)))
        }
        
        @objc func panDown(recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view!)
            switch recognizer.state {
            case .began:
                if translation.y > 0 {
                    self.workingVC?.dismiss(animated: true) {
                        self.present.dismiss = nil
                        self.present.keyView = nil
                        self.workingVC = nil
                        self.present = nil
                    }
                    self.finish()
                } else {
                    
                }
            default:
                break;
            }
        }
        
    }
}

extension DetailInteractiveTransition : UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.dismiss
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.dismiss
    }
}


