//
//  ScoreWriter.h
//  ToneBarrierScoreEditor
//
//  Created by Xcode Developer on 7/24/22.
//

@import Foundation;
@import AVFoundation;
@import AVFAudio;
@import AVRouting;
@import AVKit;
@import MediaPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface ScoreWriter : NSObject

+ (nonnull ScoreWriter *)score;

@property (strong, nonatomic) AVAudioSession    * session;
@property (strong, nonatomic) AVAudioEngine     * engine;
@property (strong, nonatomic) AVAudioSourceNode * sineWaveGenerator;

@property (strong, nonatomic) MPNowPlayingInfoCenter * nowPlayingInfoCenter;
@property (strong, nonatomic) MPRemoteCommandCenter  * remoteCommandCenter;

- (oneway void)handleAudioRouteChange:(NSNotification *)notification;
- (oneway void)toggleAudioEngineRunningStatus:(UIButton *)button;


@end

NS_ASSUME_NONNULL_END
