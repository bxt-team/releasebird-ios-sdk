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
    if (self) {
    }
    return self;
}

- (void)showButton:(NSString *)key {
    [ReleasebirdCore sharedInstance].apiKey = key;
    [self fetchWidgetSettingsFromAPI:[Config baseURL] withApiKey:key];
}

- (void)identify:(NSObject *)identifyJson {
   
}

- (void)fetchWidgetSettingsFromAPI:(NSString *)API withApiKey:(NSString *)apiKey {
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
                if ([ReleasebirdCore sharedInstance].widgetSettings != nil) {
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
    
    // Konvertiere stateIdentify in JSON-Daten
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:stateIdentify options:0 error:&error];
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
            // Handle error
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
            @try {
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([responseDict[@"valid"] boolValue]) {
                    // Handle success
                    NSMutableDictionary *state = [stateIdentify mutableCopy];
                    state[@"people"] = responseDict[@"peopleId"];
                    if (hash) {
                        state[@"hash"] = hash;
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:[NSJSONSerialization dataWithJSONObject:state options:0 error:nil] forKey:@"rbird_state"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    // Update iframe
                    NSString *CONTENT_URL = @"https://content.example.com"; // Ersetze dies durch deine CONTENT_URL
                    NSString *iframeURL = [NSString stringWithFormat:@"%@/widget?apiKey=%@&tab=HOME&people=%@&hash=%@&ai=%@", CONTENT_URL, apiKey, responseDict[@"peopleId"], hash, anonymousIdentifier];
                    [self updateIframeWithURL:iframeURL];
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

- (void)updateIframeWithURL:(NSString *)urlString {
    // Update iframe logic here
    NSLog(@"Update iframe with URL: %@", urlString);
}


@end
