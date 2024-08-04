#import "ReleasebirdCore.h"

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
        NSLog(@"AI-Wert ausgelesen: %@", storedAIValue);
        return storedAIValue;
    } else {
        NSLog(@"Kein AI-Wert gefunden.");
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

- (NSDictionary *) getIdentifyState; {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *storedState = [defaults dictionaryForKey:@"rbird_state"];
    
    if (storedState) {
        NSLog(@"Rbird State ausgelesen: %@", storedState);
        return storedState;
    } else {
        NSLog(@"Kein Rbird State gefunden.");
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
