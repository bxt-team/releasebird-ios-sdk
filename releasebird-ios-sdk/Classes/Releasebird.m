#import "Releasebird.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdFrameViewController.h"
#import "ReleasebirdUtils.h"
#import "ReleasebirdCore.h"
#import "Config.h"

@interface Releasebird ()

@end

static NSString *const kRbirdStateKey = @"rbird_state";
static NSString *const kRbirdAnonymousKey = @"releasebird_ai";
static NSString *const kRbirdUnreadKey = @"unreadMessages";
static const NSTimeInterval kRbirdTimeout = 15.0;

@implementation Releasebird

/*
 Returns a shared instance (singleton).
 */
+ (instancetype)sharedInstance
{
    static Releasebird *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Releasebird alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self startObserving];
        // Timers need the main run loop – the SDK may be created from any thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startTimer];
        });
    }
    return self;
}

- (void)startObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)invalidateTimeout {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

/// Forgets the identified user and starts a fresh anonymous session.
- (void) logout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kRbirdStateKey];
    [defaults removeObjectForKey:kRbirdUnreadKey];
    // A new anonymous id: the next person on this device must not see the previous one's conversations
    [defaults setObject:[self generateRandomString] forKey:kRbirdAnonymousKey];
    [defaults synchronize];
    [ReleasebirdOverlayUtils updateUI];
}

- (void)executeRepeatingTask {
    [self sendPingRequest:[Config baseURL] withApiKey: [ReleasebirdCore sharedInstance].apiKey andStateIdentify:[[ReleasebirdCore sharedInstance] getIdentifyState]];
}

- (void)sendPingRequest:(NSString *)API withApiKey:(NSString *)apiKey andStateIdentify:(NSDictionary *)stateIdentify {
    NSDictionary *identifyState = [[ReleasebirdCore sharedInstance] getIdentifyState];
    // Nothing to report before init or for anonymous visitors
    if (apiKey == nil || ![identifyState isKindOfClass:[NSDictionary class]] || ![identifyState[@"people"] isKindOfClass:[NSString class]]) {
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ewidget/ping", API]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRbirdTimeout;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];
    [request setValue:identifyState[@"people"] forHTTPHeaderField:@"peopleId"];
    [request setValue:[[ReleasebirdCore sharedInstance] getAIValue] forHTTPHeaderField:@"ai"];

    NSData *jsonData = [self jsonDataFromDictionary:[self wrapDictionaryWithProperties:identifyState]];
    if (!jsonData) {
        return;
    }
    [request setHTTPBody:jsonData];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Releasebird] Ping failed: %@", error.localizedDescription);
        }
    }] resume];
}

- (void)applicationWillEnterForeground {
    [[ReleasebirdCore sharedInstance] getUnreadCount];
    [self startTimer];
}

- (void)applicationDidEnterBackground {
    [self stopTimer];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.repeatingTimer invalidate];
    self.repeatingTimer = nil;
}

- (void)startTimer {
    if (!self.repeatingTimer) {
        self.repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                               target:self
                                                             selector:@selector(executeRepeatingTask)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (void)stopTimer {
    if (self.repeatingTimer) {
        [self.repeatingTimer invalidate];
        self.repeatingTimer = nil;
    }
}

- (void)initialize:(NSString *)key showButton:(BOOL)showButton {
    if (![key isKindOfClass:[NSString class]] || key.length == 0) {
        NSLog(@"[Releasebird] initialize ignored: an API key is required");
        return;
    }
    [ReleasebirdCore sharedInstance].apiKey = key;
    [ReleasebirdCore sharedInstance].noButton = !showButton;
    [self checkAndStoreAIValue];
    [self fetchWidgetSettingsFromAPI:[Config baseURL] withApiKey:key showButton:showButton];
}

- (void)showButton {
    [ReleasebirdOverlayUtils sharedInstance].hiddenByApp = NO;
    [ReleasebirdCore sharedInstance].noButton = NO;
    if ([ReleasebirdCore sharedInstance].widgetSettings != nil) {
        [ReleasebirdOverlayUtils showFeedbackButton: true];
    }
}

- (void)showWidget {
    if ([ReleasebirdCore sharedInstance].apiKey == nil) {
        NSLog(@"[Releasebird] showWidget ignored: call initialize first");
        return;
    }
    [ReleasebirdOverlayUtils showWidget];
}

- (void)hideButton {
    [ReleasebirdOverlayUtils sharedInstance].hiddenByApp = YES;
    [ReleasebirdOverlayUtils showFeedbackButton: false];
}

- (void)identify:(NSDictionary *)identifyJson {
    [self identify:identifyJson hash:nil];
}

/// For verified identities pass the HMAC-SHA256 of the external_user_id, computed on your server with the workspace's secret hash key.
- (void)identify:(NSDictionary *)identifyJson hash:(NSString *)hash {
    if ([ReleasebirdCore sharedInstance].apiKey == nil) {
        NSLog(@"[Releasebird] identify ignored: call initialize first");
        return;
    }
    // The values come from the host app: anything that cannot be sent as JSON must not crash it
    if (![identifyJson isKindOfClass:[NSDictionary class]] || ![NSJSONSerialization isValidJSONObject:identifyJson]) {
        NSLog(@"[Releasebird] identify ignored: the user properties must be a dictionary of strings, numbers, arrays and dictionaries");
        return;
    }
    NSString *cleanHash = [hash isKindOfClass:[NSString class]] && hash.length > 0 ? hash : nil;
    [self sendIdentifyCall:[Config baseURL] withApiKey:[ReleasebirdCore sharedInstance].apiKey anonymousIdentifier:[[ReleasebirdCore sharedInstance] getAIValue] andStateIdentify:identifyJson hash:cleanHash];
}

- (void)fetchWidgetSettingsFromAPI:(NSString *)API withApiKey:(NSString *)apiKey showButton:(BOOL)showButton {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ewidget", API]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRbirdTimeout;
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Releasebird] Widget settings could not be loaded: %@", error.localizedDescription);
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {
            NSLog(@"[Releasebird] Widget settings: HTTP %ld", (long)httpResponse.statusCode);
            return;
        }
        id jsonResponse = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [ReleasebirdCore sharedInstance].widgetSettings = jsonResponse;
            [ReleasebirdOverlayUtils showFeedbackButton: showButton];
        });
    }] resume];
}

- (NSString *)generateRandomString {
    NSString *characters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    NSUInteger length = 60;
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        u_int32_t randomIndex = arc4random_uniform((u_int32_t)characters.length);
        [randomString appendFormat:@"%C", [characters characterAtIndex:randomIndex]];
    }
    return randomString;
}

- (void)checkAndStoreAIValue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults stringForKey:kRbirdAnonymousKey] == nil) {
        [defaults setObject:[self generateRandomString] forKey:kRbirdAnonymousKey];
        [defaults synchronize];
    }
}

- (NSData *)jsonDataFromDictionary:(NSDictionary *) dictionary {
    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
}

- (NSDictionary *) wrapDictionaryWithProperties: (NSDictionary *) originalDictionary {
    return @{ @"properties": originalDictionary ?: @{} };
}

- (void)sendIdentifyCall:(NSString *)API withApiKey:(NSString *)apiKey anonymousIdentifier:(NSString *)anonymousIdentifier andStateIdentify:(NSDictionary *)stateIdentify hash:(NSString *)hash {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ewidget/identify", API]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRbirdTimeout;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self getCurrentTimeZone] forHTTPHeaderField:@"timezone"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];

    NSMutableDictionary *body = [[self wrapDictionaryWithProperties:stateIdentify] mutableCopy];
    if (hash) {
        body[@"hash"] = hash;
    }
    NSData *jsonData = [self jsonDataFromDictionary:body];
    if (!jsonData) {
        return;
    }
    [request setHTTPBody:jsonData];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Releasebird] identify failed: %@", error.localizedDescription);
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {
            NSLog(@"[Releasebird] identify: HTTP %ld", (long)httpResponse.statusCode);
            return;
        }
        NSDictionary *responseDict = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if (![responseDict isKindOfClass:[NSDictionary class]] || ![responseDict[@"valid"] respondsToSelector:@selector(boolValue)]
            || ![responseDict[@"valid"] boolValue] || ![responseDict[@"peopleId"] isKindOfClass:[NSString class]]) {
            return;
        }
        NSMutableDictionary *state = [stateIdentify mutableCopy];
        state[@"people"] = responseDict[@"peopleId"];
        if (hash) {
            state[@"hash"] = hash;
        }
        @try {
            // NSUserDefaults only takes property-list values (no NSNull)
            [[NSUserDefaults standardUserDefaults] setObject:state forKey:kRbirdStateKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } @catch (NSException *exception) {
            [[NSUserDefaults standardUserDefaults] setObject:@{ @"people": responseDict[@"peopleId"], @"hash": hash ?: @"" } forKey:kRbirdStateKey];
        }
        [[ReleasebirdCore sharedInstance] getUnreadCount];
    }] resume];
}

- (NSString *)getCurrentTimeZone {
    return [NSTimeZone localTimeZone].name;
}

@end
