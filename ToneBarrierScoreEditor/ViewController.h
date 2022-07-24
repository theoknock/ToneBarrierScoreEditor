//
//  ViewController.h
//  ToneBarrierScoreEditor
//
//  Created by Xcode Developer on 7/24/22.
//

@import UIKit;
@import AVKit;

NS_ASSUME_NONNULL_BEGIN

@interface ViewController : UIViewController <AVRoutePickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

@end

NS_ASSUME_NONNULL_END
