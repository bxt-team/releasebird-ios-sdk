#import "FullscreenImageViewController.h"

@interface FullscreenImageViewController ()

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation FullscreenImageViewController

- (instancetype)initWithImageURL:(NSURL *)imageURL {
    self = [super init];
    if (self) {
        _imageURL = imageURL;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // Erstellen und konfigurieren des UIImageView
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imageView];
    
    // Hinzufügen eines Tap Gestures, um den ViewController zu schließen
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFullscreen)];
    [self.view addGestureRecognizer:tap];
    
    // Laden und Anzeigen des Bildes
    [self loadImage];
}

- (void)loadImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:self.imageURL];
        UIImage *image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    });
}

- (void)dismissFullscreen {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
