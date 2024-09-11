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
    NSString *storedAIValue = [defaults stringForKey:@"ai"];
    
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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
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
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSNumber *count= jsonResponse[@"messageCount"];
                if ([count intValue] > 0) {
                    [defaults setObject:jsonResponse[@"messageCount"] forKey:@"unreadMessages"];
                } else {
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


- (NSDictionary *) getIdentifyState; {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *storedState = [defaults dictionaryForKey:@"rbird_state"];
    
    if (storedState) {
        return storedState;
    } else {
        return nil;
    }
}

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

@end 
