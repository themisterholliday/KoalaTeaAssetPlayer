//
//  PlaybackLineIndicatorView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import Foundation

public class PlaybackLineIndicatorView: UIView {
    private var centerLine: UIView?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false

        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        backgroundView.backgroundColor = Constants.BackgroundViewColor
        backgroundView.alpha = Constants.BackgroundViewAlpha
        self.addSubview(backgroundView)

        let centerLine = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: self.height))
        centerLine.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        centerLine.backgroundColor = Constants.CenterLineColor
        self.centerLine = centerLine
        self.addSubview(centerLine)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeCenterLineColor(to color: UIColor) {
        self.centerLine?.backgroundColor = color
    }

    private struct Constants {
        static let CenterLineColor = UIColor(hexString: "#36CFD3") ?? .white
        static let BackgroundViewColor = UIColor.white
        static let BackgroundViewAlpha: CGFloat = 0.70
    }
}
