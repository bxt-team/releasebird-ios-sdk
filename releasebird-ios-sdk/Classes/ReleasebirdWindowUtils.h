#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ReleasebirdWindowReadyCompletion)(void);

@interface ReleasebirdWindowUtils : NSObject

- (void)waitForKeyWindowToBeReadyWithCompletion:(ReleasebirdWindowReadyCompletion)completion;

@end

NS_ASSUME_NONNULL_END
