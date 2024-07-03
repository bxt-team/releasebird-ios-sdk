#import "ReleasebirdFrameViewController.h"
#import <SafariServices/SafariServices.h>
#import <math.h>
#import "ReleasebirdUtils.h"
#import "ReleasebirdOverlayUtils.h"

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
    
    self.view.userInteractionEnabled = YES;
    [self createWebView];
   
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

- (void)invalidateTimeout {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self invalidateTimeout];
}

- (void)closeWidget: (void (^)(void))completion {
    self.connected = NO;
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
   

    WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController* userController = [[WKUserContentController alloc] init];
    [userController addScriptMessageHandler: self name: @"rbirdCallback"];
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
    
    // URL laden
    NSURL *url = [NSURL URLWithString:@"http://localhost:4001/widget?apiKey=1cad2c1b6d7842fd937469ce3ac42ba2&ai=97f15296f2474fd8ad696c50722f6bc6&people=66294b84d8860667fa46431b&tab=HOME&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null&people=66294b84d8860667fa46431b&hash=null"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [ReleasebirdOverlayUtils showFeedbackButton: false];
    // Constraints setzen
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    
    [self.webView loadRequest: request];
}

-(void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    if ([message.name isEqualToString:@"rbirdCallback"]) {
        if ([message.body isEqualToString:@"close"]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [ReleasebirdOverlayUtils showFeedbackButton: true];
        }
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
    NSLog(@"WebView navigation failed with error: %@", error.localizedDescription);
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
    @try {
        if ([SFSafariViewController class]) {
            SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL: url];
            viewController.modalPresentationStyle = UIModalPresentationFormSheet;
            viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [presentingViewController presentViewController:viewController animated:YES completion:nil];
        } else {
            if ([[UIApplication sharedApplication] canOpenURL: url]) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL: url options:@{} completionHandler:nil];
                }
            }
        }
    } @catch (id exp) {
        
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if ([url.absoluteString hasPrefix: @"mailto:"]) {
            if ([[UIApplication sharedApplication] canOpenURL: url]) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL: url options:@{} completionHandler:nil];
                }
            }
        } else {
            [self openURLExternally: url fromViewController: self];
        }
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)pinEdgesFrom:(UIView *)subView to:(UIView *)parent {
    NSLayoutConstraint *trailing = [NSLayoutConstraint
                                    constraintWithItem: subView
                                    attribute: NSLayoutAttributeTrailing
                                    relatedBy: NSLayoutRelationEqual
                                    toItem: parent
                                    attribute: NSLayoutAttributeTrailing
                                    multiplier: 1.0f
                                    constant: 0.f];
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                       constraintWithItem: subView
                                       attribute: NSLayoutAttributeLeading
                                       relatedBy: NSLayoutRelationEqual
                                       toItem: parent
                                       attribute: NSLayoutAttributeLeading
                                       multiplier: 1.0f
                                       constant: 0.f];
    [parent addConstraint: leading];
    [parent addConstraint: trailing];
    
    NSLayoutConstraint *bottom =[NSLayoutConstraint
                                 constraintWithItem: subView
                                 attribute: NSLayoutAttributeBottom
                                 relatedBy: NSLayoutRelationEqual
                                 toItem: parent
                                 attribute: NSLayoutAttributeBottom
                                 multiplier: 1.0f
                                 constant: 0.f];
    NSLayoutConstraint *top =[NSLayoutConstraint
                              constraintWithItem: subView
                              attribute: NSLayoutAttributeTop
                              relatedBy: NSLayoutRelationEqual
                              toItem: parent
                              attribute: NSLayoutAttributeTop
                              multiplier: 1.0f
                              constant: 0.f];
    [parent addConstraint: top];
    [parent addConstraint: bottom];
}

- (void)sendSessionUpdate {
}

- (void)sendConfigUpdate {
}

@end
