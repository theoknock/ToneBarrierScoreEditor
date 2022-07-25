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
        
        [self configureAudioSourceNode];
        
        self.engine = [[AVAudioEngine alloc] init];
        [self.engine attachNode:self.sineWaveGenerator];
        [self.engine connect:self.sineWaveGenerator to:self.engine.mainMixerNode format:nil];
        self.engine.mainMixerNode.outputVolume = 1.0;
        
        [self configureAudioSession];
        
        [self configureLockScreenControls];
    }
    
    return self;
}

- (oneway void)configureAudioSession {
    self.session = [AVAudioSession sharedInstance];
    
    @try {
        __autoreleasing NSError *error = nil;
//        [self.session setCategory:AVAudioSessionCategoryPlayback error:&error];
//        [self.session setMode:AVAudioSessionModeDefault error:&error];
        [self.session setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
        [self.session setSupportsMultichannelContent:TRUE error:&error];
        [self.session setPreferredInputNumberOfChannels:2 error:&error];
        [self.session setPreferredOutputNumberOfChannels:2 error:&error];
        
        !(!error) ?: ^ (NSError ** error_t) {
            printf("Error configuring audio session:\n\t%s\n", [[*error_t debugDescription] UTF8String]);
            NSException* exception = [NSException
                                      exceptionWithName:(*error_t).domain
                                      reason:(*error_t).localizedDescription
                                      userInfo:@{@"Error Code" : @((*error_t).code)}];
            @throw exception;
        }(&error);
    } @catch (NSException *exception) {
        printf("Exception configuring audio session:\n\t%s\n\t%s\n\t%lu",
              [exception.name UTF8String],
              [exception.reason UTF8String],
              ((NSNumber *)[exception.userInfo valueForKey:@"Error Code"]).unsignedIntegerValue);
    }
}

- (void)configureAudioSourceNode {
    __block Float32 theta = 0.f;
    __block Float32 harmonic_theta = 0.f;
    const Float32 sample_rate = 44100.f;
    const Float32 frequency = 550; // left
    const Float32 harmonic_frequency = 440; // right
    const Float32 amplitude = 1.f;
    const Float32 M_PI_SQR = 2.f * M_PI;
    
    self.sineWaveGenerator = [[AVAudioSourceNode alloc] initWithRenderBlock:^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
        Float32 theta_increment = M_PI_SQR * frequency / sample_rate;
        Float32 harmonic_theta_increment = M_PI_SQR * harmonic_frequency / sample_rate;
        Float32 * buffer_left = (Float32 *)outputData->mBuffers[0].mData;
        Float32 * harmonic_buffer_right = (Float32 *)outputData->mBuffers[1].mData;
        
//        printf("\naudio_format.sampleRate == %f\nframeCount == %u\n", self.session.sampleRate, frameCount);
        for (AVAudioFrameCount frame = 0; frame < frameCount; frame++)
        {
            buffer_left[frame] = sin(theta) * amplitude;
            theta += theta_increment;
            !(theta > M_PI_SQR) ?: (theta -= M_PI_SQR);
            
            harmonic_buffer_right[frame] = sin(harmonic_theta) * amplitude;
            harmonic_theta += harmonic_theta_increment;
            !(harmonic_theta > M_PI_SQR) ?: (harmonic_theta -= M_PI_SQR);
        }
        return (OSStatus)noErr;
    }];
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
        __block NSError * error = nil;
        [_nowPlayingInfoCenter setPlaybackState:([self.session setActive:(((![_engine isRunning]) && ^ BOOL { return ([_engine startAndReturnError:&error]); }()) || ^ BOOL { [_engine stop]; return ([_engine isRunning]); }()) error:&error] & [_engine isRunning]) ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStateStopped];
        return (!error) ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusCommandFailed;
    };
    
    [[(_remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter]) playCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter stopCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter pauseCommand] addTargetWithHandler:remote_command_handler];
    [[_remoteCommandCenter togglePlayPauseCommand] addTargetWithHandler:remote_command_handler];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (oneway void)handleAudioRouteChange:(NSNotification *)notification {
    printf("\n%s\t\tsample rate == %f\n", __PRETTY_FUNCTION__, [self.session sampleRate]);
    // To reference the playPauseButton in ViewController:
    //      ((ViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController]).playPauseButton
}

- (BOOL)toggleAudioEngineRunningStatus:(UIButton *)button
{
    __block NSError * error = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [button setSelected:([self.session setActive:(((![_engine isRunning]) && ^ BOOL { [_engine startAndReturnError:&error]; return ([_engine isRunning]); }()) || ^ BOOL { [_engine stop]; return ([_engine isRunning]); }()) error:&error]) & [_engine isRunning]];
    });
    return (!error && button.isSelected);
}

@end
