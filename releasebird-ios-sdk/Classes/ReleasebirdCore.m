#import "ReleasebirdCore.h"
#import "Config.h"
@interface ReleasebirdCore ()

@end


@implementation ReleasebirdCore

/*
 Returns a shared instance (singleton).
 */
+ (instancetype)sharedInstance
{
    static ReleasebirdCore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ReleasebirdCore alloc] init];
    });
    return sharedInstance;
}

- (NSString *) getAIValue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *storedAIValue = [defaults stringForKey:@"releasebird_ai"];
    
    if (storedAIValue) {
        return storedAIValue;
    } else {
        return nil;
    }
}

- (NSString *) getUnreadMessages {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *unread = [defaults stringForKey:@"unreadMessages"];
    
    if (unread) {
        return unread;
    } else {
        return nil;
    }
}

- (void)getUnreadCount {
    NSString *urlString = [NSString stringWithFormat:@"%@/ewidget/unread", [Config baseURL]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSDictionary *identifyState = [[ReleasebirdCore sharedInstance] getIdentifyState];
    if ([ReleasebirdCore sharedInstance].apiKey == nil) {
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 15;
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[ReleasebirdCore sharedInstance].apiKey forHTTPHeaderField:@"apiKey"];
    [request setValue:identifyState[@"people"] forHTTPHeaderField:@"peopleId"];
    [request setValue:[[ReleasebirdCore sharedInstance] getAIValue] forHTTPHeaderField:@"ai"];
    
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
                NSDictionary *jsonResponse = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
                    return;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSNumber *count = [jsonResponse[@"messageCount"] isKindOfClass:[NSNumber class]] ? jsonResponse[@"messageCount"] : @0;
                if ([count intValue] > 0) {
                    [defaults setObject:count forKey:@"unreadMessages"];
                } else {
                    [defaults removeObjectForKey:@"unreadMessages"];
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


- (NSDictionary *) getIdentifyState; {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *storedState = [defaults dictionaryForKey:@"rbird_state"];
    
    if (storedState) {
        return storedState;
    } else {
        return nil;
    }
}

- (NSString *)stringSetting:(NSString *)key {
    id value = [self.widgetSettings isKindOfClass:[NSDictionary class]] ? self.widgetSettings[key] : nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return [value isKindOfClass:[NSString class]] && [value length] > 0 ? value : nil;
}

- (float)floatSetting:(NSString *)key fallback:(float)fallback {
    id value = [self.widgetSettings isKindOfClass:[NSDictionary class]] ? self.widgetSettings[key] : nil;
    return [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : fallback;
}

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

@end 
