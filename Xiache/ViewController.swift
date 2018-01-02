//
//  ViewController.swift
//  Xiache
//
//  Created by 杜标 on 2017/12/26.
//  Copyright © 2017年 weakup. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var headImageView: UIImageView!
    @IBOutlet weak var headTitleLabel: UILabel!
    @IBOutlet weak var mainScroller: UIScrollView!
    
    var detailTransition: DetailInteractiveTransition!
    var currentIndex: Int!
    let colors = [
        UIColor.red,
        UIColor.yellow,
        UIColor.gray,
        UIColor.green,
        UIColor.blue,
        UIColor.purple,
        UIColor.brown
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailTransition = DetailInteractiveTransition()
        detailTransition.delegate = self
        let views = colors.enumerated().map { (index, color) -> MyView in
            let view = MyView()
            view.color = color
            view.index = index
            view.backgroundColor = color
            mainScroller.addSubview(view)
            view.autoresizingMask = .flexibleHeight
            view.frame = mainScroller.bounds.offsetBy(dx: CGFloat(index) * mainScroller.bounds.width, dy: 0);
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleRightMargin]
            print("frame: \(view.frame) color: \(String(describing: color.cgColor.components)) index: \(index)" )
            return view
        }
        
        
//
        views.forEach { (view) in
            detailTransition.bind(toView: view)
        }
//        mainScroller.addGestureRecognizer(panner)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
        mainScroller.contentSize = CGSize(width: mainScroller.frame.width * CGFloat(colors.count), height: mainScroller.bounds.height)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: TransitionDelegate {
    
    func frameInScreen(forView view: UIView) -> CGRect {
        return self.mainScroller.frame
    }
    
    func initViewController(fromView: UIView, andPresentAnimate present: (UIViewController, TransitableViewController) -> ()) -> TransitableViewController! {
        if let view = fromView as? MyView {
            let color = view.color
            let index = view.index
            currentIndex = index
            let dvc = DetailViewController()
            dvc.detailCallback = self
            dvc.show(detail: (color!, index ?? 0))
            present(self, dvc)
            return dvc
        }
        return nil
    }
}

extension ViewController: DetailChangeCallback {
    func getNextDetail() -> (color: UIColor, index: Int)! {
        if (currentIndex + 1 >= colors.count || currentIndex + 1 < 0) {
            return nil
        } else {
            if let currentIndex = currentIndex {
                return (colors[currentIndex + 1], currentIndex + 1)
            } else {
                return nil
            }
        }
    }
    
    func getPreviousDetail() -> (color: UIColor, index: Int)! {
        if (currentIndex - 1 >= colors.count || currentIndex - 1 < 0) {
            return nil
        } else {
            if let currentIndex = currentIndex {
                return (colors[currentIndex - 1], currentIndex - 1)
            } else {
                return nil
            }
        }
    }

    func dismissDetailViewController() {
        self.dismiss(animated: true) {
            self.currentIndex = nil
        }
    }
    
    func updateDetailIndex(index: Int) {
        currentIndex = index
        scroll(toIndex: currentIndex)
    }
    
    func scroll(toIndex: Int) {
        let newKeyView = mainScroller.subviews[toIndex]
        print("scroll new: \(newKeyView.frame)", "wehen \(mainScroller.contentOffset)")
        self.detailTransition.keyView = newKeyView
        mainScroller.scrollRectToVisible(newKeyView.frame , animated: false)
        print("scrolled \(mainScroller.contentOffset)")
    }
}

