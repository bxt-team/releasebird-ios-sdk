#import "ReleasebirdButton.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdUtils.h"
#import "ReleasebirdCore.h"

const double kButtonDimension = 56.0;
const float kNotificationBadgeDimension = 22.0;

const double BUTTON_SIZE = 56.0;
const float NOTIFICATION_BADGE_SIZE = 22.0;

@implementation ReleasebirdButton

- (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
    if (self) {
        [self initialize];
    }
    return self;
}

- (NSString *)generateRandomHexString {
    int length = 32;
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    NSString *letters = @"0123456789abcdef";
    
    for (int i = 0; i < length; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    
    return randomString;
}

- (void)initialize {
    self.autoresizingMask = UIViewAutoresizingNone;
    self.hidden = YES;
    
    float padding = (kButtonDimension - (kButtonDimension * 0.64)) / 2.0;
    self.logoView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, kButtonDimension - (padding * 2), kButtonDimension - (padding * 2))];
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.userInteractionEnabled = YES;
    [self addSubview:self.logoView];
    
    self.tag = INT_MAX;
    
    if (@available(iOS 11.0, *)) {
        UILayoutGuide *layoutGuide = self.safeAreaLayoutGuide;
        _safeAreaConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:layoutGuide attribute:NSLayoutAttributeLeft multiplier:1 constant:-12];

        _edgeConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:-12];

        [self adjustConstraintsForOrientation];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *aiString = [defaults objectForKey:@"releasebird_ai"];
    if (aiString == nil) {
        [defaults setObject:[self generateRandomHexString] forKey:@"releasebird_ai"];
        [defaults synchronize];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)refreshVisibility {
    if (!self.initialized) {
        [self configure];
    }
    
    [self displayButtonIfNeeded];
}

- (void)displayButtonIfNeeded {
    if (![ReleasebirdOverlayUtils sharedInstance].showButton) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
}

- (void)configure {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        return;
    }
    
    // Already initialized.
    if (self.initialized) {
        return;
    }
    
    // Button initialized.
    self.initialized = YES;
    
    // Update the visibility.
    [self refreshVisibility];
    
    self.layer.shadowRadius  = 6.0;
    self.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    self.layer.shadowOpacity = 0.2;
    self.layer.masksToBounds = NO;
    self.clipsToBounds = NO;
    
    self.backgroundColor = [ReleasebirdUtils colorFromHexString: @"#485bff"];
    
    [self createButton];
}


- (void)handleOrientationChange:(NSNotification *)notification {
    [self adjustConstraintsForOrientation];
}

- (UIInterfaceOrientation)reliableInterfaceOrientation {
    UIInterfaceOrientation deviceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (deviceOrientation == UIDeviceOrientationUnknown) {
        if (@available(iOS 13.0, *)) {
            deviceOrientation = [UIApplication sharedApplication].windows.firstObject.windowScene.interfaceOrientation;
        }
    }
    
    return deviceOrientation;
}

- (void)adjustConstraintsForOrientation {
        
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self adjustConstraintsForOrientation];
        });
        return;
    }
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
        return;
    }
    
    if (self.safeAreaConstraint == nil || self.edgeConstraint == nil) {
        return;
    }
    
    bool shouldActivateSafeAreaConstraint = NO;
    bool shouldActivateEdgeConstraint = NO;
    
    @try {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            shouldActivateSafeAreaConstraint = NO;
            shouldActivateEdgeConstraint = YES;
        } else {
            UIInterfaceOrientation orientation = [self reliableInterfaceOrientation];
            
            if ([self.feedbackButtonPosition isEqualToString: @"left"]) {
                if (orientation == UIDeviceOrientationLandscapeLeft) {
                    shouldActivateEdgeConstraint = NO;
                    shouldActivateSafeAreaConstraint = YES;
                } else {
                    shouldActivateSafeAreaConstraint = NO;
                    shouldActivateEdgeConstraint = YES;
                }
            } else {
                if (orientation == UIDeviceOrientationLandscapeRight) {
                    shouldActivateEdgeConstraint = NO;
                    shouldActivateSafeAreaConstraint = YES;
                } else {
                    shouldActivateSafeAreaConstraint = NO;
                    shouldActivateEdgeConstraint = YES;
                }
            }
        }
        
        NSMutableArray *toActivate = [[NSMutableArray alloc] init];
        NSMutableArray *toDeactivate = [[NSMutableArray alloc] init];
        
        if (shouldActivateSafeAreaConstraint) {
            [toActivate addObject: self.safeAreaConstraint];
        } else {
            [toDeactivate addObject: self.safeAreaConstraint];
        }
        
        if (shouldActivateEdgeConstraint) {
            [toActivate addObject: self.edgeConstraint];
        } else {
            [toDeactivate addObject: self.edgeConstraint];
        }
        
        if (toDeactivate.count > 0) {
            [NSLayoutConstraint deactivateConstraints: toDeactivate];
        }
        
        if (toActivate.count > 0) {
            [NSLayoutConstraint activateConstraints: toActivate];
        }
    } @catch (id anException) {
        
    }
}

- (void)safelyActivateConstraints:(NSArray<NSLayoutConstraint *> *)constraints {
    for (NSLayoutConstraint *constraint in constraints) {
        if (constraint == nil) {
            NSLog(@"Releasebird: Attempted to activate a nil constraint.");
            continue;
        }

        if (constraint.firstItem == nil || constraint.secondItem == nil) {
            NSLog(@"Releasebird: Constraint has nil items: %@", constraint);
            continue;
        }

        UIView *firstView = [constraint.firstItem isKindOfClass:[UIView class]] ? (UIView *)constraint.firstItem : nil;
        if (firstView && ![firstView isDescendantOfView: self]) {
            NSLog(@"Releasebird: First item of constraint is not in the view hierarchy: %@", constraint);
            continue;
        }
        
        UIView *secondView = [constraint.secondItem isKindOfClass:[UIView class]] ? (UIView *)constraint.secondItem : nil;
        if (secondView && ![secondView isDescendantOfView: self]) {
            NSLog(@"Releasebird: Second item of constraint is not in the view hierarchy: %@", constraint);
            continue;
        }

        @try {
            [NSLayoutConstraint activateConstraints:@[constraint]];
        } @catch (NSException *exception) {
            NSLog(@"Releasebird: Exception activating constraint: %@, Exception: %@", constraint, exception);
        }
    }
}

- (void)createButton {
   
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.cornerRadius = kButtonDimension / 2.0;
    NSLog(@"bin hier");
    NSLog(@"Widget Settings3: %@", [ReleasebirdCore sharedInstance].widgetSettings);
    self.feedbackButtonPosition = [ReleasebirdCore sharedInstance].widgetSettings[@"launcherPosition"];
    
    NSString *buttonLogo = @"https://sdk.gleap.io/res/chatbubble.png";

    if (![buttonLogo isEqualToString: self.currentButtonUrl]) {
        self.currentButtonUrl = buttonLogo;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: buttonLogo]];
            if (data == nil) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.logoView != nil) {
                    self.logoView.hidden = NO;
                    self.logoView.image = [UIImage imageWithData: data];
                    [self displayButtonIfNeeded];
                }
            });
        });
    }
    
    
    float buttonX = [[ReleasebirdCore sharedInstance].widgetSettings[@"spaceLeftRight"] floatValue];
    float buttonY = [[ReleasebirdCore sharedInstance].widgetSettings[@"spaceBottom"] floatValue];
    
    if (self.superview != nil) {
        NSLayoutConstraint *yConstraint;
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kButtonDimension];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:kButtonDimension];
        
        if (@available(iOS 11, *)) {
            UILayoutGuide *guide = self.superview.safeAreaLayoutGuide;
            
            if ([self.feedbackButtonPosition isEqualToString: @"left"]) {
                _edgeConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem: self.superview attribute:NSLayoutAttributeLeading multiplier:1 constant: buttonX];
                
                if (@available(iOS 11, *)) {
                    UILayoutGuide *guide = self.superview.safeAreaLayoutGuide;
                    _safeAreaConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeLeading multiplier:1 constant: buttonX];
                }
            } else {
                _edgeConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem: self.superview attribute:NSLayoutAttributeTrailing multiplier:1 constant: -buttonX];
                
                if (@available(iOS 11, *)) {
                    UILayoutGuide *guide = self.superview.safeAreaLayoutGuide;
                    _safeAreaConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeTrailing multiplier:1 constant: -buttonX];
                }
            }
            
            yConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:guide attribute:NSLayoutAttributeBottom multiplier:1 constant: -buttonY];
        }
        
        [NSLayoutConstraint activateConstraints:@[yConstraint, widthConstraint, heightConstraint]];
        
        [self adjustConstraintsForOrientation];
        
        [self addBadge];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)addBadge {
    self.notificationBadgeView = [[UIView alloc] initWithFrame: CGRectMake(self.frame.size.width - (NOTIFICATION_BADGE_SIZE - 5.0), -5.0, NOTIFICATION_BADGE_SIZE, NOTIFICATION_BADGE_SIZE)];
        self.notificationBadgeView.backgroundColor = [UIColor redColor];
        self.notificationBadgeView.layer.cornerRadius = NOTIFICATION_BADGE_SIZE / 2.0;
        self.notificationBadgeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview: self.notificationBadgeView];
        self.notificationBadgeView.hidden = YES;
        
        [_notificationBadgeView.heightAnchor constraintEqualToConstant: NOTIFICATION_BADGE_SIZE].active = YES;
        [_notificationBadgeView.widthAnchor constraintEqualToConstant: NOTIFICATION_BADGE_SIZE].active = YES;
        [_notificationBadgeView.trailingAnchor constraintEqualToAnchor: self.trailingAnchor constant: 5.0].active = YES;
        [_notificationBadgeView.topAnchor constraintEqualToAnchor: self.topAnchor constant: -5.0].active = YES;
        
        self.notificationBadgeLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, NOTIFICATION_BADGE_SIZE, NOTIFICATION_BADGE_SIZE)];
        self.notificationBadgeLabel.font = [UIFont systemFontOfSize: 11 weight: UIFontWeightBold];
        self.notificationBadgeLabel.textColor = [UIColor whiteColor];
        self.notificationBadgeLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.notificationBadgeView addSubview: self.notificationBadgeLabel];
}

-(void)showBadge {
    self.notificationBadgeView.hidden = NO;
}

-(void)hideBadge {
    self.notificationBadgeView.hidden = YES;
}

-(void)setBadgeText:(NSString *)value {
    self.notificationBadgeLabel.text = value;
}

@end
