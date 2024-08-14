#import "Releasebird.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdFrameViewController.h"
#import "ReleasebirdUtils.h"
#import "ReleasebirdCore.h"
#import "Config.h"

@interface Releasebird ()

@end


static id ObjectOrNull(id object)
{
  return object ?: [NSNull null];
}

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
    [self startTimer];
    [self startObserving];
    if (self) {
    }
    return self;
}

- (void)startObserving {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self invalidateTimeout];
}


- (void)invalidateTimeout {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void)executeRepeatingTask {
    NSLog(@"executeRepeatingTask called");
    [self sendPingRequest:[Config baseURL] withApiKey: [ReleasebirdCore sharedInstance].apiKey andStateIdentify:[[ReleasebirdCore sharedInstance] getIdentifyState]];
}

- (void)sendPingRequest:(NSString *)API withApiKey:(NSString *)apiKey andStateIdentify:(NSDictionary *)stateIdentify {
    // Erstelle die URL
    NSString *urlString = [NSString stringWithFormat:@"%@/ewidget/ping", API];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Erstelle die URLRequest
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];
    
    NSDictionary *identifyState = [[ReleasebirdCore sharedInstance] getIdentifyState];
    
    [request setValue:identifyState[@"people"] forHTTPHeaderField:@"peopleId"];
    [request setValue:[[ReleasebirdCore sharedInstance] getAIValue] forHTTPHeaderField:@"ai"];
    
    // Konvertiere stateIdentify in JSON-Daten
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: [self wrapDictionaryWithProperties:stateIdentify] options:0 error:&error];
    if (!jsonData) {
        NSLog(@"Error serializing JSON: %@", error.localizedDescription);
        return;
    }
    [request setHTTPBody:jsonData];
    
    // Erstelle die URLSession
    NSURLSession *session = [NSURLSession sharedSession];
    
    // Erstelle den Daten-Task
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            NSLog(@"Request was successful.");
            // Verarbeite die Antwortdaten hier
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"Response Data: %@", responseDict);
        } else {
            NSLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
        }
    }];
    
    // Starte den Task
    [dataTask resume];
}

- (void)applicationWillEnterForeground {
    // Aktion ausführen, wenn die App in den Vordergrund kommt
    [[ReleasebirdCore sharedInstance] getUnreadCount];
    [self startTimer];
}

- (void)applicationDidEnterBackground {
    NSLog(@"App did enter background");
    [self stopTimer];
}

- (void)dealloc {
    // Abmelden von Benachrichtigungen
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Timer invalidieren
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

- (void)initialize:(NSString *)key showButton:(BOOL *)showButton {
    [ReleasebirdCore sharedInstance].apiKey = key;
    [self checkAndStoreAIValue];
    [self fetchWidgetSettingsFromAPI:[Config baseURL] withApiKey:key showButton:showButton];
    
}

- (void)showButton {
    NSLog(@"PRobiere Zeige Button");
    if ([ReleasebirdCore sharedInstance].widgetSettings != nil) {
        NSLog(@"Zeige Button");
        [ReleasebirdOverlayUtils showFeedbackButton: true];
    }
}

- (void)hideButton {
    [ReleasebirdOverlayUtils showFeedbackButton: false];
}

- (void)identify:(NSDictionary *)identifyJson {
    [self sendIdentifyCall:[Config baseURL] withApiKey:[ReleasebirdCore sharedInstance].apiKey anonymousIdentifier:[[ReleasebirdCore sharedInstance] getAIValue] andStateIdentify:identifyJson hash:nil];
}

- (void)fetchWidgetSettingsFromAPI:(NSString *)API withApiKey:(NSString *)apiKey showButton:(BOOL *)showButton {
    NSString *urlString = [NSString stringWithFormat:@"%@/ewidget", API];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];
    
    NSURLSession *session = [NSURLSession sharedSession];
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
                [ReleasebirdCore sharedInstance].widgetSettings = jsonResponse;
                NSLog(@"Widget Settings4: %@", [ReleasebirdCore sharedInstance].widgetSettings);
                if (showButton) {
                    [ReleasebirdOverlayUtils showFeedbackButton: true];
                }
                
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

- (NSString *)generateRandomString {
    NSString *characters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    NSUInteger length = 60;
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (NSUInteger i = 0; i < length; i++) {
        u_int32_t randomIndex = arc4random_uniform((u_int32_t)characters.length);
        unichar randomChar = [characters characterAtIndex:randomIndex];
        [randomString appendFormat:@"%C", randomChar];
    }
    
    return randomString;
}

- (void)checkAndStoreAIValue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedAIValue = [defaults stringForKey:@"ai"];
    
    if (storedAIValue == nil) {
        NSString *newAIValue = [self generateRandomString];
        [defaults setObject:newAIValue forKey:@"ai"];
        [defaults synchronize];
        
        NSLog(@"Neuer AI-Wert generiert und gespeichert: %@", newAIValue);
    } else {
        // Wert vorhanden, nichts zu tun
        NSLog(@"AI-Wert bereits vorhanden: %@", storedAIValue);
    }
}

- (NSData *)jsonDataFromDictionary:(NSDictionary *) dictionary {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:nil];
    return jsonData;
}

- (NSDictionary *) wrapDictionaryWithProperties: (NSDictionary *) originalDictionary {
    NSDictionary *newDictionary = @{
        @"properties": originalDictionary
        //@"hash": null
    };
    return newDictionary;
}

- (void)sendIdentifyCall:(NSString *)API withApiKey:(NSString *)apiKey anonymousIdentifier:(NSString *)anonymousIdentifier andStateIdentify:(NSDictionary *)stateIdentify hash:(NSString *)hash {
    // Erstelle die URL
    NSString *urlString = [NSString stringWithFormat:@"%@/ewidget/identify", API];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Erstelle die URLRequest
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self getCurrentTimeZone] forHTTPHeaderField:@"timezone"];
    [request setValue:apiKey forHTTPHeaderField:@"apiKey"];
    
    NSData *jsonData = [self jsonDataFromDictionary: [self wrapDictionaryWithProperties:stateIdentify]];
    
    [request setHTTPBody:jsonData];
    
    // Erstelle die URLSession
    NSURLSession *session = [NSURLSession sharedSession];
    
    // Erstelle den Daten-Task
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            // Handle error
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
            @try {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSLog(@"hab die response %@", responseDict);
                
                if ([responseDict[@"valid"] boolValue]) {
                    NSLog(@"bin valid");
                    // Handle success
                    NSMutableDictionary *state = [stateIdentify mutableCopy];
                    state[@"people"] = responseDict[@"peopleId"];
                    if (hash) {
                        state[@"hash"] = hash;
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:state forKey:@"rbird_state"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    NSLog(@"hab gesetzt");
                    
                }
            } @catch (NSException *exception) {
                // Handle error
                NSLog(@"Exception: %@", exception.reason);
            }
        } else {
            // Handle HTTP error
            NSLog(@"HTTP Error: %ld", (long)httpResponse.statusCode);
        }
    }];
    
    // Starte den Task
    [dataTask resume];
}

- (NSString *)getCurrentTimeZone {
    return [NSTimeZone localTimeZone].name;
}


@end
