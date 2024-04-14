# AZVideoPlayer

The `VideoPlayer` provided by `SwiftUI` out of the box is great but it's missing one very important feature: full screen presentation mode. `AZVideoPlayer` behaves pretty much exactly like `VideoPlayer`, but adds the button that's provided by `AVPlayerViewController` to go full screen. This fork includes PIP support 2024

### Basic Usage

```swift
import SwiftUI
import AVKit
import AZVideoPlayer

struct ContentView: View {
    var player: AVPlayer?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
    }
    
    var body: some View {
        AZVideoPlayer(player: player)
            .aspectRatio(16/9, contentMode: .fit)
            // Adding .shadow(radius: 0) is necessary if
            // your player will be in a List on iOS 16.
            .shadow(radius: 0)
    }
}
```

### Advanced Usage

I had a couple more reasons for making this package:
1. Make it easy to reset the video player when the view disappears.
2. Have the video continue playing when ending full screen presentation (it defaults to pausing when full screen mode ends).

Here's an example of how `AZVideoPlayer` can be used to do that:

```swift
import SwiftUI
import AVKit
import AZVideoPlayer

struct ContentView: View {
    var player: AVPlayer?
    @State var willBeginFullScreenPresentation: Bool = false
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
    }
    
    var body: some View {
        AZVideoPlayer(player: player,
                      willBeginFullScreenPresentationWithAnimationCoordinator: willBeginFullScreen,
                      willEndFullScreenPresentationWithAnimationCoordinator: willEndFullScreen,
                      statusDidChange: statusDidChange,
                      showsPlaybackControls: true,
                      entersFullScreenWhenPlaybackBegins: false,
                      pausesWhenFullScreenPlaybackEnds: false) {
        .aspectRatio(16/9, contentMode: .fit)
        // Adding .shadow(radius: 0) is necessary if
        // your player will be in a List on iOS 16.
        .shadow(radius: 0)
        .onDisappear {
            // onDisappear is called when full screen presentation begins, but the view is
            // not actually disappearing in this case so we don't want to reset the player
            guard !willBeginFullScreenPresentation else {
                willBeginFullScreenPresentation = false
                return
            }
            player?.pause()
            player?.seek(to: .zero)
        }
    }
    
    func willBeginFullScreen(_ playerViewController: AVPlayerViewController,
                             _ coordinator: UIViewControllerTransitionCoordinator) {
        willBeginFullScreenPresentation = true
    }
    
    func willEndFullScreen(_ playerViewController: AVPlayerViewController,
                           _ coordinator: UIViewControllerTransitionCoordinator) {
    }
    
    func statusDidChange(_ status: AZVideoPlayerStatus) {
        print(status.timeControlStatus.rawValue)
        print(status.volume)
    }
}
```
