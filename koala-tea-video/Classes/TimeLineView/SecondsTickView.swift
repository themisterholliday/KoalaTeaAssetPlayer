//
//  SecondsTickView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 9/4/18.
//

import Foundation

public class SecondsTickView: UIView {
    func setupWithSeconds(seconds: Double, cropViewFrame: CGRect) {
        let width = cropViewFrame.width - (Constants.CropViewBorderWidth * 2)
        self.frame = CGRect(origin: CGPoint(x: cropViewFrame.minX + Constants.CropViewBorderWidth, y: self.frame.minY),
                            size: CGSize(width: width, height: self.frame.height))

        let totalWidth = Double(width)
        let widthPerSecond = totalWidth / seconds
        let numberOfTicksPerSecond: Double = 2

        let tickWidthWithSpacing = (widthPerSecond / numberOfTicksPerSecond)
        let numberOfTotalTicks = (totalWidth / tickWidthWithSpacing)

        let tickWidth: CGFloat = 1

        // @TODO: Add last tick if duration is not event
        var counter = 0.0
        for i in 0...(numberOfTotalTicks.rounded().int) {
            var height = Constants.ShorterTickHeight
            var color = Constants.ShorterTickColor

            let x: CGFloat = i.cgFloat * tickWidthWithSpacing.cgFloat

            if i.double.truncatingRemainder(dividingBy: numberOfTotalTicks).int.isEven {
                color = Constants.LongerTickColor
                // Longer height
                height = Constants.LongerTickHeight

                // Add time code label
                let label = UILabel(frame: CGRect(x: x + (tickWidth / 2) + Constants.LabelXSpacing,
                                                  y: height + Constants.LabelTopSpacing,
                                                  width: Constants.LabelWidthAndHeight,
                                                  height: Constants.LabelWidthAndHeight))
                label.font = UIFont.systemFont(ofSize: Constants.LabelFontSize)

                label.text = "0" + String(counter.int)
                label.textColor = color
                label.textAlignment = .center
                self.addSubview(label)

                counter += 1
            }

            let view = UIView(frame: CGRect(x: x, y: 0, width: tickWidth, height: height))
            view.backgroundColor = color
            self.addSubview(view)
        }
    }

    private struct Constants {
        static let CropViewBorderWidth: CGFloat = 4
        static let ShorterTickHeight: CGFloat = 3
        static let LongerTickHeight: CGFloat = 5
        static let ShorterTickColor = UIColor(red: 0.67, green: 0.70, blue: 0.70, alpha: 1.0)
        static let LongerTickColor = UIColor(red: 0.19, green: 0.19, blue: 0.21, alpha: 1.0)
        static let LabelXSpacing: CGFloat = -6
        static let LabelTopSpacing: CGFloat = 1
        static let LabelWidthAndHeight: CGFloat = 12
        static let LabelFontSize: CGFloat = 9
    }
}
