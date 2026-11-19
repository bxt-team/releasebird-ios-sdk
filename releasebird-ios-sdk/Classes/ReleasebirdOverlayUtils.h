#import <Foundation/Foundation.h>
#import "ReleasebirdButton.h"
#import "ReleasebirdUIOverlayViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdOverlayUtils : NSObject

+ (instancetype)sharedInstance;
+ (void)showFeedbackButton:(bool)show;
+ (void)clear;
+ (void)updateUI;
+ (void)showWidget;

@property (nonatomic, assign) bool showButton;
@property (nonatomic, assign) bool showButtonExternalOverwrite;

/// The host app hid the button – it stays hidden until the app shows it again.
@property (nonatomic, assign) bool hiddenByApp;
@property (nonatomic, retain) ReleasebirdUIOverlayViewController *uiOverlayViewController;
@property (nonatomic, retain) NSMutableArray *notifications;

@end

NS_ASSUME_NONNULL_END
