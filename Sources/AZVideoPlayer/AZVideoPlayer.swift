//
//  AZVideoPlayer.swift
//  AZVideoPlayer
//
//  Created by Adam Zarn on 7/4/22.
//

import Foundation
import SwiftUI
import AVKit

public struct AZVideoPlayer: UIViewControllerRepresentable {
    
    public typealias TransitionCompletion = (AVPlayerViewController, UIViewControllerTransitionCoordinator) -> Void
    public typealias PipCompletion = (AVPlayerViewController) -> Void
    public typealias Volume = Float
    public typealias StatusDidChange = (AZVideoPlayerStatus) -> Void
    
    let player: AVPlayer?
    let controller = AVPlayerViewController()
    let willBeginFullScreenPresentationWithAnimationCoordinator: TransitionCompletion?
    let willEndFullScreenPresentationWithAnimationCoordinator: TransitionCompletion?
    let statusDidChange: StatusDidChange?
    let showsPlaybackControls: Bool
    var allowsPictureInPicturePlayback: Bool
    let entersFullScreenWhenPlaybackBegins: Bool
    let pausesWhenFullScreenPlaybackEnds: Bool
    let playerViewControllerWillStartPictureInPicture: PipCompletion?
    let playerViewControllerDidStartPictureInPicture: PipCompletion?
    let playerViewControllerWillStopPictureInPicture: PipCompletion?
    let playerViewControllerDidStopPictureInPicture: PipCompletion?
    
    //@Binding var allowsPictureInPicturePlayback: Bool
    
    public init(player: AVPlayer?,
                willBeginFullScreenPresentationWithAnimationCoordinator: TransitionCompletion? = nil,
                willEndFullScreenPresentationWithAnimationCoordinator: TransitionCompletion? = nil,
                playerViewControllerWillStartPictureInPicture: PipCompletion? = nil,
                playerViewControllerDidStartPictureInPicture: PipCompletion? = nil,
                playerViewControllerWillStopPictureInPicture: PipCompletion? = nil,
                playerViewControllerDidStopPictureInPicture: PipCompletion? = nil,
                statusDidChange: StatusDidChange? = nil,
                showsPlaybackControls: Bool = true,
                allowsPictureInPicturePlayback: Bool = true,
                entersFullScreenWhenPlaybackBegins: Bool = false,
                pausesWhenFullScreenPlaybackEnds: Bool = false) {
        self.player = player
        self.willBeginFullScreenPresentationWithAnimationCoordinator = willBeginFullScreenPresentationWithAnimationCoordinator
        self.willEndFullScreenPresentationWithAnimationCoordinator = willEndFullScreenPresentationWithAnimationCoordinator
        self.playerViewControllerWillStartPictureInPicture = playerViewControllerWillStartPictureInPicture
        self.playerViewControllerDidStartPictureInPicture = playerViewControllerDidStartPictureInPicture
        self.playerViewControllerWillStopPictureInPicture = playerViewControllerWillStopPictureInPicture
        self.playerViewControllerDidStopPictureInPicture = playerViewControllerDidStopPictureInPicture
        self.statusDidChange = statusDidChange
        self.showsPlaybackControls = showsPlaybackControls
        self.allowsPictureInPicturePlayback = allowsPictureInPicturePlayback
        self.entersFullScreenWhenPlaybackBegins = entersFullScreenWhenPlaybackBegins
        self.pausesWhenFullScreenPlaybackEnds = pausesWhenFullScreenPlaybackEnds
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        controller.player = player
        controller.showsPlaybackControls = showsPlaybackControls
        controller.entersFullScreenWhenPlaybackBegins = entersFullScreenWhenPlaybackBegins
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = allowsPictureInPicturePlayback
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        return controller
    }
    
    public func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
        controller.allowsPictureInPicturePlayback = allowsPictureInPicturePlayback
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self, statusDidChange)
    }
    
    public final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: AZVideoPlayer
        var statusDidChange: StatusDidChange?
        var previousTimeControlStatus: AVPlayer.TimeControlStatus?
        var timeControlStatusObservation: NSKeyValueObservation?
        var shouldEnterFullScreenPresentationOnNextPlay: Bool = true
        
        func shouldEnterFullScreenPresentation(of player: AVPlayer) -> Bool {
            guard parent.entersFullScreenWhenPlaybackBegins else { return false }
            return player.timeControlStatus == .playing && shouldEnterFullScreenPresentationOnNextPlay
        }
        
        init(_ parent: AZVideoPlayer,
             _ statusDidChange: StatusDidChange? = nil) {
            self.parent = parent
            self.statusDidChange = statusDidChange
            super.init()
            self.timeControlStatusObservation = self.parent.player?.observe(\.timeControlStatus,
                                                                             changeHandler: { [weak self] player, _ in
                statusDidChange?(AZVideoPlayerStatus(timeControlStatus: player.timeControlStatus, volume: player.volume))
                if self?.shouldEnterFullScreenPresentation(of: player) == true {
                    parent.controller.enterFullScreenPresentation(animated: true)
                } else if player.timeControlStatus == .playing {
                    self?.shouldEnterFullScreenPresentationOnNextPlay = true
                }
                self?.previousTimeControlStatus = player.timeControlStatus
            })
        }
        
        public func playerViewController(_ playerViewController: AVPlayerViewController,
                                         willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            parent.willBeginFullScreenPresentationWithAnimationCoordinator?(playerViewController, coordinator)
        }
        
        public func playerViewController(_ playerViewController: AVPlayerViewController,
                                         willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            if !parent.pausesWhenFullScreenPlaybackEnds {
                continuePlayingIfPlaying(parent.player, coordinator)
            }
            parent.willEndFullScreenPresentationWithAnimationCoordinator?(playerViewController, coordinator)
        }
        
        func continuePlayingIfPlaying(_ player: AVPlayer?,
                                      _ coordinator: UIViewControllerTransitionCoordinator) {
            let isPlaying = player?.timeControlStatus == .playing
            coordinator.animate(alongsideTransition: nil) { _ in
                if isPlaying {
                    self.shouldEnterFullScreenPresentationOnNextPlay = false
                    player?.play()
                }
            }
        }
        
        public func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            debugPrint("playerViewControllerWillStartPictureInPicture")
            parent.playerViewControllerWillStartPictureInPicture?(playerViewController)
        }
                
        public func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            debugPrint("playerViewControllerDidStartPictureInPicture")
            parent.playerViewControllerDidStartPictureInPicture?(playerViewController)
        }
                
        public func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            debugPrint("playerViewControllerWillStopPictureInPicture")
            parent.playerViewControllerWillStopPictureInPicture?(playerViewController)
        }
                
        public func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            debugPrint("playerViewControllerDidStopPictureInPicture")
            parent.playerViewControllerDidStopPictureInPicture?(playerViewController)
        }
        
    }
}
