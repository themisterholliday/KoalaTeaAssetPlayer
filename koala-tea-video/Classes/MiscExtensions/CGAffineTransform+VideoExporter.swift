//
//  CGAffineTransform+VideoExporter.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//

import Foundation

public extension CGAffineTransform {
    init(from: CGRect, toRect to: CGRect) {
        self.init(translationX: to.minX - from.minX, y: to.minY - from.minY)
        self = self.scaledBy(x: to.width / from.width, y: to.height / from.height)
    }
}
