//
//  VideoExporterOrientationHelper.swift
//  KoalaTeaVideo
//
//  Created by Craig Holliday on 7/7/19.
//

import Foundation

public class VideoExporterOrientationHelper {
    public static func rotation(from transform: CGAffineTransform) -> CGFloat {
        return atan2(transform.b, transform.a)
    }

    public static func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
}

public extension CGAffineTransform {
    var currentRotation: CGFloat {
        return atan2(self.b, self.a)
    }
}
