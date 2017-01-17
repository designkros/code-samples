//
//  IntroViewController.swift
//  Sample
//
//  Created by Michael Rose on 11/16/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit
import DataManager

class IntroViewController: UIViewController {
    
    @IBOutlet weak var navBar: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewCnTop: NSLayoutConstraint!
    @IBOutlet weak var scrollViewCnBottom: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labelCnHeight: NSLayoutConstraint!
    @IBOutlet weak var labelCnLeft: NSLayoutConstraint!
    @IBOutlet weak var labelCnRight: NSLayoutConstraint!
    var labelMargin: CGFloat!
    
    var attributedStrings = [NSAttributedString]()
    var currentIndex: Int = -1
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Set flag on AccountHelper
        AccountHelper.userHasSeenIntro = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup views array
        let viewA = createImageView(image: UIImage(named: "viewB")!)
        scrollView.addSubview(viewA)
        
        let viewB = createImageView(image: UIImage(named: "viewA")!)
        scrollView.addSubview(viewB)

        let viewC = createImageView(image: UIImage(named: "viewC")!)
        scrollView.addSubview(viewC)
        
        // Scroll view content margins
        let scrollViewMargin = ScreenSizeHelper.constant(iPhoneSE: 10.0, iPhoneStandard: 10.0, iPhonePlus: 30.0)
        scrollViewCnTop.constant = scrollViewMargin
        scrollViewCnBottom.constant = scrollViewMargin
        
        // Label margins
        labelMargin = ScreenSizeHelper.constant(iPhoneSE: 30.0, iPhoneStandard: 30.0, iPhonePlus: 50.0)
        labelCnLeft.constant = labelMargin
        labelCnRight.constant = labelMargin
        
        // Setup text array
        let plistStrings = PList.dataFromInfoPListWithKey("PageControlText") as! [String]
        for string in plistStrings {
            let attributedString = NSAttributedString(string: string, attributes: textAttributes())
            attributedStrings.append(attributedString)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        // Adjust scroll view content
        let width = scrollView.bounds.size.width
        let height = scrollView.bounds.size.height
        for (index, view) in scrollView.subviews.enumerated() {
            view.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        }
        scrollView.contentSize = CGSize(width: width * CGFloat(scrollView.subviews.count), height: height)
        
        // Init!
        if currentIndex == -1 {
            updateCurrentIndex(index: 0, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        //
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func createImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }
    
    func textAttributes() -> [String : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.0
        paragraphStyle.alignment = .center
        let font = UIFont.AvenirNextRegular(size: 15.0)
    
        return [ NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle ]
    }
    
    func updateCurrentIndex(index: Int, animated: Bool = true) {
        if index != currentIndex && index >= 0 && index < scrollView.subviews.count {
            currentIndex = index
            
            // Update back button
            let hidden = self.currentIndex == 0
            if animated {
                UIView.transition(with: navBar, duration: 0.3, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
                    self.backButton.isHidden = hidden
                }, completion: nil)
            } else {
                self.backButton.isHidden = hidden
            }
            
            // Update page control
            pageControl.currentPage = self.currentIndex
            
            // Update label text
            let text = attributedStrings[currentIndex]
            if animated {
                UIView.transition(with: label, duration: 0.3, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
                    self.label.attributedText = text
                }, completion: nil)
            } else {
                self.label.attributedText = text
            }
            
            // Update label height
            let textHeight = text.height(containerWidth: view.bounds.size.width - (labelMargin * 2.0))
            labelCnHeight.constant = textHeight
            if animated {
                UIView.animate(withDuration: 0.35, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    // MARK: - IBACTION
    
    @IBAction func didBack() {
        if (currentIndex > 0) {
            let point = CGPoint(x: scrollView.bounds.size.width * CGFloat(currentIndex - 1), y: 0)
            scrollView.setContentOffset(point, animated: true)
        }
    }
    
    @IBAction func didSkip() {
        performSegue(withIdentifier: "showTermsSegue", sender: self)
    }
    
    @IBAction func didNext() {
        if (currentIndex < scrollView.subviews.count-1) {
            let point = CGPoint(x: scrollView.bounds.size.width * CGFloat(currentIndex + 1), y: 0)
            scrollView.setContentOffset(point, animated: true)
        } else {
            performSegue(withIdentifier: "showTermsSegue", sender: self)
        }
    }

}

extension IntroViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Calculate current index
        let index =  Int(round(scrollView.contentOffset.x/scrollView.frame.size.width))
        updateCurrentIndex(index: index)
    }
    
}
