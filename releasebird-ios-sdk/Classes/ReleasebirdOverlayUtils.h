#import <Foundation/Foundation.h>
#import "ReleasebirdButton.h"
#import "ReleasebirdUIOverlayViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdOverlayUtils : NSObject

+ (instancetype)sharedInstance;
+ (void)showFeedbackButton:(bool)show;
+ (void)clear;
+ (void)updateUI;

@property (nonatomic, assign) bool showButton;
@property (nonatomic, assign) bool showButtonExternalOverwrite;
@property (nonatomic, retain) ReleasebirdUIOverlayViewController *uiOverlayViewController;
@property (nonatomic, retain) NSMutableArray *notifications;

@end

NS_ASSUME_NONNULL_END
