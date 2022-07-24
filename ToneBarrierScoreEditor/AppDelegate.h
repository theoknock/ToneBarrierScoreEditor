//
//  AppDelegate.h
//  ToneBarrierScoreEditor
//
//  Created by Xcode Developer on 7/24/22.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

#define AppServices ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define RootViewController ((ViewController *)((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;


@interface AppDelegate : UIResponder <UIApplicationDelegate>


@end

