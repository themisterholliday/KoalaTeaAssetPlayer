//
//  TimelineCropView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import Foundation

public class TimelineCropView: UIView {
    required public init(widthPerSecond: Double,
                         maxVideoDurationInSeconds: Double,
                         height: CGFloat,
                         center: CGPoint) {
        let cropViewFrame = CGRect(x: 0, y: 0, width: CGFloat(widthPerSecond * maxVideoDurationInSeconds) + (Constants.BorderWidth * 2), height: height)
        super.init(frame: cropViewFrame)

        self.layer.borderWidth = Constants.BorderWidth
        self.isUserInteractionEnabled = false
        self.center = center
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func changeBorderColor(to color: UIColor) {
        self.layer.borderColor = color.cgColor
    }

    private struct Constants {
        static let BorderWidth: CGFloat = 4
    }
}
