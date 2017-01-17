//
//  WheelLayout.swift
//  Sample
//
//  Created by Michael Rose on 6/22/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

class WheelLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
        self.scrollDirection = .Vertical
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return false
    }
    
}
