#import "ReleasebirdButton.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdUtils.h"
#import "ReleasebirdCore.h"
#import "Config.h"

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


- (void)getUnreadCount {
    NSLog(@"bin in unread");
    NSString *urlString = [NSString stringWithFormat:@"%@/ewidget/unread", [Config baseURL]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *identifyState = [[ReleasebirdCore sharedInstance] getIdentifyState];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[ReleasebirdCore sharedInstance].apiKey forHTTPHeaderField:@"apiKey"];
    [request setValue:identifyState[@"people"] forHTTPHeaderField:@"peopleId"];
    [request setValue:[[ReleasebirdCore sharedInstance] getAIValue] forHTTPHeaderField:@"ai"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSLog(@"Make call");
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            // Handle error
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
            @try {
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSLog(@"Unred: %@", jsonResponse);
                NSLog(@"Messages: %@", jsonResponse[@"messageCount"]);
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSNumber *count= jsonResponse[@"messageCount"];
                NSLog(@"count %@", count);
                if ([count intValue] > 0) {
                    NSLog(@"setzr value");
                    [defaults setObject:jsonResponse[@"messageCount"] forKey:@"unreadMessages"];
                } else {
                    NSLog(@"Setze nil");
                    [defaults setObject:nil forKey:@"unreadMessages"];
                }
                
                [defaults synchronize];
            } @catch (NSException *exception) {
                // Handle parsing error
                NSLog(@"Parsing exception: %@", exception.reason);
            }
        } else {
            NSLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
        }
    }];
    
    [dataTask resume];
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
    
    self.backgroundColor = [ReleasebirdUtils colorFromHexString: [ReleasebirdCore sharedInstance].widgetSettings[@"backgroundColor"]];
    
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
    self.feedbackButtonPosition = [ReleasebirdCore sharedInstance].widgetSettings[@"launcherPosition"];
    NSLog(@"%@", [ReleasebirdCore sharedInstance].widgetSettings[[NSString stringWithFormat:@"chatBubbleUrl%@", [ReleasebirdCore sharedInstance].widgetSettings[@"launcher"]]]);
    NSString *buttonLogo = [ReleasebirdCore sharedInstance].widgetSettings[[NSString stringWithFormat:@"chatBubbleUrl%@", [ReleasebirdCore sharedInstance].widgetSettings[@"launcher"]]];

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
    [self startObserving];
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
        [self getUnreadCount];
        
}


- (void)startObserving {
    // Beobachter für Änderungen in NSUserDefaults einrichten
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)stopObserving {
    // Beobachter entfernen
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];
}


- (void)userDefaultsDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *count = [[ReleasebirdCore sharedInstance] getUnreadMessages];
        if (count != nil) {
            [self setBadgeText:[[ReleasebirdCore sharedInstance] getUnreadMessages]];
        } else {
            [self hideBadge];
        }
        
    });
}

-(void)showBadge {
    self.notificationBadgeView.hidden = NO;
}

-(void)hideBadge {
    self.notificationBadgeView.hidden = YES;
}

-(void)setBadgeText:(NSString *)value {
    self.notificationBadgeView.hidden = NO;
    self.notificationBadgeLabel.text = value;
}

@end
