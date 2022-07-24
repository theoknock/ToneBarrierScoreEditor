//
//  ViewController.m
//  ToneBarrierScoreEditor
//
//  Created by Xcode Developer on 7/24/22.
//


#import "ViewController.h"
#import "ScoreWriter.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet AVRoutePickerView *routePicker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.playPauseButton setImage:[UIImage systemImageNamed:@"pause.rectangle"] forState:UIControlStateSelected];
    [self.playPauseButton setImage:[UIImage systemImageNamed:@"play.rectangle"]  forState:UIControlStateNormal];
    [self.playPauseButton setImage:[UIImage systemImageNamed:@"play.slash"]   forState:UIControlStateDisabled];
    
    [self.routePicker setDelegate:(id<AVRoutePickerViewDelegate> _Nullable)self];
}

- (IBAction)togglePlayPause:(UIButton *)sender forEvent:(UIEvent *)event {
    [ScoreWriter.score toggleAudioEngineRunningStatus:sender];
}



@end
