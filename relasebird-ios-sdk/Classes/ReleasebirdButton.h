#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdButton : UIView

@property (nonatomic, retain) UIImageView *logoView;

- (void)configure;
- (void)refreshVisibility;

@property (nonatomic, assign) bool initialized;
@property (nonatomic, assign) bool showButton;
@property (nonatomic, retain) NSString *currentButtonUrl;
@property (strong, nonatomic) NSLayoutConstraint *safeAreaConstraint;
@property (strong, nonatomic) NSLayoutConstraint *edgeConstraint;
@property (strong, nonatomic) NSString *feedbackButtonPosition;



@end

NS_ASSUME_NONNULL_END
