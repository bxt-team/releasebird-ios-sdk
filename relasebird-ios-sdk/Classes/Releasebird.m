#import "Releasebird.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdFrameViewController.h"
#import "ReleasebirdUtils.h"

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

- (void)showButton {
   
    [ReleasebirdOverlayUtils showFeedbackButton: true];
    //[self showWidget];

   
  
}

@end
