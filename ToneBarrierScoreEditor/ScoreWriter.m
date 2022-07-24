//
//  ScoreWriter.m
//  ToneBarrierScoreEditor
//
//  Created by Xcode Developer on 7/24/22.
//

#import "ScoreWriter.h"
#import "ViewController.h"
#import "AppDelegate.h"

@implementation ScoreWriter

static Float32 (^(^(^randomize)(void))(Float32(^)(Float32)))(void) = ^{
    srand48((unsigned int)time(0));
    return ^ (Float32(^scale)(Float32)) {
        static Float32 random;
        return ^ Float32 {
            return (Float32)scale((random = drand48()));
        };
    };
};

static Float32 (^rescale)(Float32) = ^ Float32 (Float32 distributed_random) {
    Float32 range_max = 1.f, range_min = -1.f;
    return (distributed_random = (distributed_random * (range_max - range_min)) + range_min);
};

static Float32 (^whiteNoise)(void);


static ScoreWriter *score = NULL;
+ (nonnull ScoreWriter *)score
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
        if (!score)
        {
            score = [[self alloc] init];
        }
    });
    
    return score;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        [self configureAudioSession];

        __block Float32 theta = 0.f;
        const Float32 frequency = 440.f;
        const Float32 sampleRate = 48000.f;
        const Float32 amplitude = 0.25f;
        const Float32 M_PI_SQR = 2.f * M_PI;
        
        self.sineWaveGenerator = [[AVAudioSourceNode alloc] initWithRenderBlock:^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
            Float32 theta_increment = M_PI_SQR * frequency / sampleRate;
            Float32 * buffer = (Float32 *)outputData->mBuffers[0].mData;
            for (AVAudioFrameCount frame = 0; frame < frameCount; frame++)
            {
                buffer[frame] = sin(theta) * amplitude;
                theta += theta_increment;
                !(theta > M_PI_SQR) ?: (theta -= M_PI_SQR);
            }
            return (OSStatus)noErr;
        }];
        
        self.engine = [[AVAudioEngine alloc] init];
        [self.engine attachNode:self.sineWaveGenerator];
        [self.engine connect:self.sineWaveGenerator to:self.engine.mainMixerNode format:nil];
        self.engine.mainMixerNode.outputVolume = 1.0;
        
        [self configureLockScreenControls];
    }
    
    return self;
}

- (oneway void)configureAudioSession {
    self.session = [AVAudioSession sharedInstance];
    
    __autoreleasing NSError *error = nil;
    [self.session setSupportsMultichannelContent:TRUE error:&error];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [self.session setMode:AVAudioSessionModeDefault error:&error];
    [self.session setActive:YES error:&error];
    
    if (error) printf("\nError configuring audio session: %s\n\n", [error.debugDescription UTF8String]);
}

- (oneway void)configureLockScreenControls {
    NSMutableDictionary<NSString *, id> * nowPlayingInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    [nowPlayingInfo setObject:@"ToneBarrier" forKey:MPMediaItemPropertyTitle];
    [nowPlayingInfo setObject:(NSString *)@"James Alan Bush" forKey:MPMediaItemPropertyArtist];
    [nowPlayingInfo setObject:(NSString *)@"The Life of a Demoniac" forKey:MPMediaItemPropertyAlbumTitle];
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(180.0, 180.0) requestHandler:^ UIImage * _Nonnull (CGSize size) {
        
        UIImage * image;
        [(image = [UIImage systemImageNamed:@"waveform.path"
                          withConfiguration:[[UIImageSymbolConfiguration configurationWithPointSize:size.width weight:UIImageSymbolWeightLight] configurationByApplyingConfiguration:[UIImageSymbolConfiguration configurationWithHierarchicalColor:[UIColor colorWithRed:0.f green:122.f/255.f blue:1.f alpha:.2f]]]]) imageByPreparingForDisplay];
        return image;
    }];
    
    [nowPlayingInfo setObject:(MPMediaItemArtwork *)artwork forKey:MPMediaItemPropertyArtwork];
    
    [(_nowPlayingInfoCenter = [MPNowPlayingInfoCenter defaultCenter]) setNowPlayingInfo:(NSDictionary<NSString *,id> * _Nullable)nowPlayingInfo];
    
    MPRemoteCommandHandlerStatus (^remote_command_handler)(MPRemoteCommandEvent * _Nonnull) = ^ MPRemoteCommandHandlerStatus (MPRemoteCommandEvent * _Nonnull event) {
        __autoreleasing NSError * error = nil;
        [_nowPlayingInfoCenter setPlaybackState:((![_engine isRunning]) && [_engine startAndReturnError:&error]) || ^ BOOL { [_engine stop]; return [_engine isRunning]; }() ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStateStopped];
        return (!error) ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
    };
    
    [[(_remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter]) playCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter stopCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter pauseCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter togglePlayPauseCommand] addTargetWithHandler:remote_command_handler];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (oneway void)handleAudioRouteChange:(NSNotification *)notification {
    printf("\n%s\n", __PRETTY_FUNCTION__);
}

- (oneway void)toggleAudioEngineRunningStatus:(UIButton *)button
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [button setSelected:((![_engine isRunning]) && [_engine startAndReturnError:nil]) || ^ BOOL { [_engine stop]; return [_engine isRunning]; }()];
    });
}

@end
