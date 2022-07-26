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

id (^retainable_object_)(id(^)(void)) = ^ id (id(^object)(void)) {
    return ^{
        return object();
    };
};

id (^(^retain_object_)(id(^)(void)))(void) = ^ (id(^retainable_object)(void)) {
    id retained_object = retainable_object();
    return ^ id {
        return retained_object;
    };
};

unsigned long counter = 0;

static typeof(unsigned long (^)(unsigned long)) recursive_iterator_;
static void (^(^iterator_)(const unsigned long))(id(^)(void)) = ^ (const unsigned long object_count) {
    NSLog(@"\niterator object_count == %lu\n", object_count);
    typeof(id(^)(void)) retained_objects_ref;
    return ^ (id * retained_objects_t) {
        NSLog(@"\nretained_objects_t == %p\n", &retained_objects_t);
        return ^ (id(^object)(void)) {
            NSLog(@"\nobject == %p\n", &object);
//            typeof(recursive_iterator_) recursive_iterator_t;
            recursive_iterator_ = ^ unsigned long (unsigned long index) {
                printf("object %lu (or %lu) of %lu\n", index, [(NSNumber *)(object()) unsignedLongValue], object_count);
                return (index & 1UL) && (unsigned long)(recursive_iterator_)((index >>= 1));
            }; (recursive_iterator_)((unsigned long)(~(1UL << (object_count + 1))));
        };
    }((id *)&retained_objects_ref);
};

- (void)test_iterator {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    id (^object_)(void) = ^{
        NSNumber * number = @(++counter);
        return number;
    };
    
    iterator_(10)(object_);
}

/*
 -----------------------------------------------------
 */

static Float32 (^(^(^randomize)(void))(Float32(^)(Float32)))(void) = ^{
    srand48((unsigned int)time(0));
    return ^ (Float32(^scale)(Float32)) {
        static Float32 random;
        return ^ Float32 {
            return (Float32)scale((random = drand48()));
        };
    };
};

static double (^note)(double) = ^ double (double distributed_random_value) {
    return distributed_random_value; //(distributed_random_value = pow(1.059463094f, distributed_random_value) * 440.0);
};

static double (^random_value_distributor)(double) = ^ double (double random_value) {
    double range_max = 880, range_min = 440;
    return (random_value = (random_value * (range_max - range_min)) + range_min);
};

static double (^(^(^random_value_generator)(double(^)(double)))(double(^)(double)))(void) = ^ (double(^distributor)(double)) {
    srand48((unsigned int)time(0));
    return ^ (double(^number)(double)) {
        static double random;
        return ^ double {
            return number(distributor((random = drand48())));
        };
    };
};

/*
 -----------------------------------------------------
 */


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
        [self test_iterator];
        
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
    // Tone Barrier Score: two-second tone-pair dyad spec: https://lucid.app/lucidchart/f0bddc19-d731-45d6-9add-161efa37149c/edit?viewport_loc=-68%2C707%2C1916%2C1085%2C0_0&invitationId=inv_c87eb120-ece2-4394-81af-1833f78d5577#
    
    // Signal-generation parameters
    
    double (^distributed_random_value)(void) = random_value_generator(random_value_distributor)(note);

    
    __block Float32 theta = 0.f;
    __block Float32 harmonic_theta = 0.f;
    const Float32 sample_rate = 44100.f;
    __block Float32 frequency = distributed_random_value(); // left
    __block Float32 harmonic_frequency = distributed_random_value(); // right
    const Float32 amplitude = 1.f;
    const Float32 M_PI_SQR = 2.f * M_PI;
    
    // Tone set A and B
    
    
    self.sineWaveGenerator = [[AVAudioSourceNode alloc] initWithRenderBlock:^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
        Float32 theta_increment = M_PI_SQR * frequency / sample_rate;
        Float32 harmonic_theta_increment = M_PI_SQR * harmonic_frequency / sample_rate;
        Float32 * buffer_left = (Float32 *)outputData->mBuffers[0].mData;
        Float32 * harmonic_buffer_right = (Float32 *)outputData->mBuffers[1].mData;

        AVAudioFrameCount frame = 0;
        for (; frame < frameCount;)
        {
            buffer_left[frame] = sin(theta) * amplitude;
            theta += theta_increment;
            !(theta > M_PI_SQR) ?: (theta -= M_PI_SQR);
            
            harmonic_buffer_right[frame] = sin(harmonic_theta) * amplitude;
            harmonic_theta += harmonic_theta_increment;
            !(harmonic_theta > M_PI_SQR) ?: (harmonic_theta -= M_PI_SQR);
            if ((frame++) == (frameCount - 1)) {
                NSLog(@"frame = %u", frame);
                frequency = distributed_random_value(); // left
                harmonic_frequency = distributed_random_value(); // right
            }
        }
        
        return (OSStatus)noErr;
    }];
}

- (oneway void)configureLockScreenControls {
    NSMutableDictionary<NSString *, id> * nowPlayingInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
    [nowPlayingInfo setObject:@"ToneBarrier" forKey:MPMediaItemPropertyTitle];
    [nowPlayingInfo setObject:(NSString *)@"James Alan Bush" forKey:MPMediaItemPropertyArtist];
    [nowPlayingInfo setObject:(NSString *)@"The Life of a Demoniac" forKey:MPMediaItemPropertyAlbumTitle];
    
    static UIImage * image;
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:(image = [UIImage imageNamed:@"WaveIcon"])];
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
