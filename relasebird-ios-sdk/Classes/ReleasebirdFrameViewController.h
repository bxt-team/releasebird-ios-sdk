#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ReleasebirdFrameManagerDelegate <NSObject>
@optional
- (void) connected;
- (void) failedToConnect;
@required
@end

@interface ReleasebirdFrameViewController : UIViewController <WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>

- (void)sendMessageWithData:(NSDictionary *)data;
- (void)sendSessionUpdate;
- (void)sendConfigUpdate;
- (id)initWithFormat:(NSString *)format;

@property (nonatomic, retain, nullable) NSTimer* timeoutTimer;
@property (nonatomic, assign) bool isCardSurvey;
@property (nonatomic, assign) bool connected;
@property (nonatomic, weak) id <ReleasebirdFrameManagerDelegate> delegate;
@property (strong, nonatomic) NSTimer *repeatingTimer;


@end

NS_ASSUME_NONNULL_END
