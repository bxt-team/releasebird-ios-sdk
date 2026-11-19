#import "ReleasebirdFrameViewController.h"
#import <SafariServices/SafariServices.h>
#import <math.h>
#import "ReleasebirdUtils.h"
#import "Releasebird.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdCore.h"
#import "Config.h"
#import "FullscreenImageViewController.h"
#import "ReleasebirdCore.h"


/// The web view's content controller retains its message handler. Passing the view controller
/// directly creates a retain cycle (it would never be released) – this proxy only holds it weakly.
@interface ReleasebirdWeakScriptHandler : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation ReleasebirdWeakScriptHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface ReleasebirdFrameViewController ()

@property (retain, nonatomic) WKWebView *webView;
@property (retain, nonatomic) UIView *loadingView;
@property (retain, nonatomic) UIActivityIndicatorView *loadingActivityView;

@end

static id ObjectOrNull(id object)
{
    return object ?: [NSNull null];
}

@implementation ReleasebirdFrameViewController

- (id)initWithFormat:(NSString *)format
{
    self = [super initWithNibName: nil bundle:nil];
    if (self != nil)
    {
        self.connected = NO;
        self.view.backgroundColor = [UIColor colorWithRed: 1.0 green: 1.0 blue: 0.0 alpha: 0.0];
        
    }
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.preferredContentSize = CGSizeMake(400, 700);
    }
    
    self.view.userInteractionEnabled = YES;
    [self createWebView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    // Timer starten, wenn die App im Vordergrund is
    [[ReleasebirdCore sharedInstance] getUnreadCount];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"rbirdCallback"];
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
}


- (NSDictionary *) wrapDictionaryWithProperties: (NSDictionary *) originalDictionary {
    NSDictionary *newDictionary = @{
        @"properties": originalDictionary
        //@"hash": null
    };
    return newDictionary;
}

- (void)applicationWillEnterForeground {
   
}

- (void)applicationDidEnterBackground {

}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [ReleasebirdOverlayUtils showFeedbackButton: true];
}

- (void)closeWidget: (void (^)(void))completion {
    self.connected = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.presentingViewController != nil) {
            [self dismissViewControllerAnimated:YES completion:completion];
        } else if (completion) {
            completion();
        }
    });
}


- (void)sendMessageWithData:(NSDictionary *)data {
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject: data
                                                           options: 0
                                                             error:&error];
        if (!jsonData) {
            NSLog(@"[Releasebird] Error sending message: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    [self.webView evaluateJavaScript: [NSString stringWithFormat: @"sendMessage(%@)", jsonString] completionHandler: nil];
                }
                @catch(id exception) {}
            });
        }
    }
    @catch(id exception) {}
}

- (void)stopLoading {
    if (self.loadingView != nil) {
        [self.loadingView setHidden: YES];
    }
    self.view.userInteractionEnabled = YES;
    self.webView.alpha = 1.0;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        completionHandler();
    }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *url = navigationAction.request.URL;
    [self openURLExternally: url fromViewController: self];
    return nil;
}

- (void)createWebView {
    if ([ReleasebirdCore sharedInstance].apiKey == nil) {
        return;
    }
    WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc] init];
    ReleasebirdWeakScriptHandler *handler = [[ReleasebirdWeakScriptHandler alloc] init];
    handler.target = self;
    [userController addScriptMessageHandler: handler name: @"rbirdCallback"];
    webConfiguration.userContentController = userController;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = UIColor.clearColor;
    self.webView.scrollView.backgroundColor = UIColor.clearColor;
    self.webView.userInteractionEnabled = YES;
    self.webView.scrollView.bounces = NO;
    self.webView.scrollView.alwaysBounceVertical = NO;
    self.webView.scrollView.alwaysBounceHorizontal = NO;
    self.webView.allowsBackForwardNavigationGestures = NO;
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.backgroundColor = [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.0];
    
    NSDictionary *identifyState = [[ReleasebirdCore sharedInstance] getIdentifyState];
    NSString *peopleId = [identifyState[@"people"] isKindOfClass:[NSString class]] ? identifyState[@"people"] : @"null";
    // The hash of a verified identity travels along – without it the widget treats the user as unverified
    NSString *hash = [identifyState[@"hash"] isKindOfClass:[NSString class]] && [identifyState[@"hash"] length] > 0 ? identifyState[@"hash"] : @"null";

    NSURLComponents *components = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@/widget", [Config contentUrl]]];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"apiKey" value:[ReleasebirdCore sharedInstance].apiKey],
        [NSURLQueryItem queryItemWithName:@"ai" value:[[ReleasebirdCore sharedInstance] getAIValue] ?: @""],
        [NSURLQueryItem queryItemWithName:@"people" value:peopleId],
        [NSURLQueryItem queryItemWithName:@"tab" value:@"HOME"],
        [NSURLQueryItem queryItemWithName:@"hash" value:hash],
        [NSURLQueryItem queryItemWithName:@"disableScreenCapture" value:@"true"],
    ];
    NSURL *url = components.URL;
    if (url == nil) {
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    
    [ReleasebirdOverlayUtils showFeedbackButton: false];
    if (@available(iOS 11.0, *)) {
        // Constraints setzen
        [NSLayoutConstraint activateConstraints:@[
            [self.webView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
            [self.webView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
            [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
            [self.webView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
        ]];
    }
    
    [self.webView loadRequest: request];
}


// Wird aufgerufen, wenn der Webinhalt-Prozess beendet wird
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    // iOS ended the web process (memory pressure) – reload instead of leaving a blank screen
    [webView reload];
}

-(void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    if (![message.name isEqualToString:@"rbirdCallback"]) {
        return;
    }
    if ([message.body isKindOfClass:[NSString class]]) {
        if ([message.body isEqualToString:@"close"]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [ReleasebirdOverlayUtils showFeedbackButton: true];
        } else if ([message.body isEqualToString:@"newMessageArrived"]) {
            [[ReleasebirdCore sharedInstance] getUnreadCount];
        }
    } else if ([message.body isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)message.body;
        if ([dictionary[@"key"] isKindOfClass:[NSString class]] && [dictionary[@"key"] isEqualToString:@"showImage"]
            && [dictionary[@"url"] isKindOfClass:[NSString class]]) {
            NSURL *imageUrl = [NSURL URLWithString:dictionary[@"url"]];
            // only real web addresses – the value comes from the page
            if (imageUrl != nil && ([imageUrl.scheme isEqualToString:@"https"] || [imageUrl.scheme isEqualToString:@"http"])) {
                FullscreenImageViewController *fullscreenVC = [[FullscreenImageViewController alloc] initWithImageURL:imageUrl];
                [self presentViewController:fullscreenVC animated:YES completion:nil];
            }
        }
    }
}



// Wird aufgerufen, nachdem der ViewController aus einem Container-ViewController entfernt wurde
- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (!parent) {
        NSLog(@"didMoveToParentViewController: ViewController wurde aus dem Container entfernt");
    }
}


// WKNavigationDelegate method to inject the viewport meta tag
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSString *js = @"var meta = document.createElement('meta');"
    "meta.name = 'viewport';"
    "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';"
    "document.getElementsByTagName('head')[0].appendChild(meta);";
    [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self loadingFailed: error];
}

- (void)addFullConstraintsFrom:(UIView *)view toOtherView:(UIView *)otherView {
    [otherView addConstraint:[NSLayoutConstraint constraintWithItem: view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem: otherView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [otherView addConstraint:[NSLayoutConstraint constraintWithItem: view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [otherView addConstraint:[NSLayoutConstraint constraintWithItem: view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem: otherView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    [otherView addConstraint:[NSLayoutConstraint constraintWithItem: view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem: otherView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self loadingFailed: error];
}

- (void)requestTimedOut:(id)sender {
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(failedToConnect)]) {
        [self.delegate failedToConnect];
    }
    [self closeWidget: nil];
}

- (void)loadingFailed:(NSError *)error {
    // A cancelled load (e.g. a link opened outside the widget) is not a failure
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        return;
    }
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        return;
    }
    if (self.presentedViewController != nil) {
        return;
    }
    self.view.userInteractionEnabled = YES;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: error.localizedDescription
                                                                             message: nil
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        [self closeWidget: nil];
    }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)openURLExternally:(NSURL *)url fromViewController:(UIViewController *)presentingViewController {
    if (url == nil) {
        return;
    }
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL: url];
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [presentingViewController presentViewController:viewController animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL: url options:@{} completionHandler:nil];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [self openURLExternally: navigationAction.request.URL fromViewController: self];
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)sendSessionUpdate {
}

- (void)sendConfigUpdate {
}

@end
