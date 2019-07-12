//
//  PlayerControlsView.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import Foundation

public class PlayerControlsView: UIView {
    private lazy var slider: UISlider = {
        let slider = UISlider()
        return slider
    }()

    required init() {
        super.init(frame: .zero)

        addSubview(slider)
        slider.layout {
            $0.bottom == self.bottomAnchor - 20
            $0.leading == self.leadingAnchor + 20
            $0.trailing == self.trailingAnchor - 20
            $0.height.equal(to: self.heightAnchor, multiplier: 0.2)
        }
        
        slider.maximumValue = 100
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class AssetPlayerView: UIView {
    private let playerView: PlayerView
    private lazy var controlsView = PlayerControlsView()
//    private let yt: YTPlayerView

    public required init(assetPlayer: AssetPlayer) {
        playerView = assetPlayer.playerView
//        yt = YTPlayerView(assetPlayer: assetPlayer)
        super.init(frame: .zero)

//        addSubview(playerView)
//        playerView.constrainEdgesToSuperView()

//        addSubview(controlsView)
//        controlsView.constrainEdgesToSuperView()

//        addSubview(yt)
//        yt.constrainEdgesToSuperView()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
