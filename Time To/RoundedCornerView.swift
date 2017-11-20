//
//  RoundedCornerView.swift
//  roundedCorner
//
//  Created by Axel Kee on 25/09/2017.
//  Copyright © 2017 Sweatshop. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedCornerView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
	
	// if cornerRadius variable is set/changed, change the corner radius of the UIView
	@IBInspectable var cornerRadius: CGFloat = 0 {
		didSet {
			layer.cornerRadius = cornerRadius
			layer.masksToBounds = cornerRadius > 0
		}
	}
	
	@IBInspectable var borderWidth: CGFloat = 0 {
		didSet {
			layer.borderWidth = borderWidth
		}
	}
	
	@IBInspectable var borderColor: UIColor? {
		didSet {
			layer.borderColor = borderColor?.cgColor
		}
	}
	
}
