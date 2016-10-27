

#import <WebKit/WebKit.h>
#import "FDRWebViewController.h"
//#import "SwizzeMethod.h"
//#import "RNCachingURLProtocol.h"
#import <objc/runtime.h>
//#import "LCActionSheet.h"

//injected javascript
static NSString *const kTouchJavaScriptString =
@"document.ontouchstart=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:start:\"+x+\":\"+y;};\
document.ontouchmove=function(event){\
x=event.targetTouches[0].clientX;\
y=event.targetTouches[0].clientY;\
document.location=\"myweb:touch:move:\"+x+\":\"+y;};\
document.ontouchcancel=function(event){\
document.location=\"myweb:touch:cancel\";};\
document.ontouchend=function(event){\
document.location=\"myweb:touch:end\";};";

static NSString *const kImageJS               = @"keyForImageJS";
static NSString *const kImage                 = @"keyForImage";


@interface FDRWebViewController ()<UIActionSheetDelegate,WKNavigationDelegate,WKUIDelegate,UIGestureRecognizerDelegate, WKScriptMessageHandler>
@property (assign, nonatomic) NSUInteger loadCount;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) WKWebView *wkWebView;


@property (nonatomic, strong) NSString *imageJS;
@property (strong, nonatomic) UIImage *image;

@end

@implementation FDRWebViewController
#pragma mark - seter and getter

- (void)setImageJS:(NSString *)imageJS
{
    objc_setAssociatedObject(self, &kImageJS, imageJS, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)imageJS
{
    return objc_getAssociatedObject(self, &kImageJS);
}

- (void)setImage:(UIImage *)image
{
    objc_setAssociatedObject(self, &kImage, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image
{
    return objc_getAssociatedObject(self, &kImage);
}

/** 传入控制器、url、标题 */
+ (void)showWithContro:(UIViewController *)contro withUrlStr:(NSString *)urlStr withTitle:(NSString *)title {
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    FDRWebViewController *webContro = [FDRWebViewController new];
    webContro.homeUrl = [NSURL URLWithString:urlStr];
    webContro.title = title;
    webContro.hidesBottomBarWhenPushed = YES;
    [contro.navigationController pushViewController:webContro animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor greenColor];
    [self configUI];
//    [self configBackItem];
//    UILongPressGestureRecognizer *longPressed = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
//    longPressed.delegate = self;
//    longPressed.minimumPressDuration = 0.8;
//    [self.wkWebView addGestureRecognizer:longPressed];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"reloadJSData" object:nil];
}

- (void)configUI {
    
    // 进度条
//    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
//    progressView.tintColor = FDR_THEME_COLOR;
//    progressView.trackTintColor = [UIColor whiteColor];
//    [self.view addSubview:progressView];
//    self.progressView = progressView;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    // web内容处理池
    config.processPool = [[WKProcessPool alloc] init];
    
    // 通过JS与webview内容交互
    config.userContentController = [[WKUserContentController alloc] init];
    // 注入JS对象名称AppModel，当JS通过AppModel来调用时，
    // 我们可以在WKScriptMessageHandler代理中接收到
    [config.userContentController addScriptMessageHandler:self name:@"login"];
    
    //h5文档开始加载时执行：  设置token
//    WKUserScript * tokenScript = [[WKUserScript alloc]
//                                  initWithSource: @"document.cookie = 'token=TeskCookieValue1';"
//                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    
    WKUserScript * tokenScript = [[WKUserScript alloc]
                                  initWithSource:[NSString stringWithFormat:@"document.cookie = 'token=%@'",@"i am token"]
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    
    [config.userContentController addUserScript:tokenScript];

    // 显示WKWebView
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    wkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    wkWebView.backgroundColor = [UIColor whiteColor];
    wkWebView.navigationDelegate = self;
    wkWebView.UIDelegate = self;
    wkWebView.backgroundColor = [UIColor greenColor];
  
//    [self.view insertSubview:wkWebView belowSubview:progressView];
    
    [wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_homeUrl];
    [request addValue:@"ios" forHTTPHeaderField:@"system"];
//    [request addValue:[[YSUserManager share] token] forHTTPHeaderField:@"token"];
    [request addValue:@"1" forHTTPHeaderField:@"userType"];
    
    //    [wkWebView loadRequest:request];
    
     self.wkWebView = wkWebView;
    
    
    
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1/iweb/test.php"]]];
    [self.view addSubview:self.wkWebView];

}

- (void)configBackItem {
    
    // 导航栏的返回按钮
    UIImage *backImage = [UIImage imageNamed:@"返回按钮"];
//    backImage = [backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
//    [backBtn setTintColor:FDR_THEME_COLOR];
//    [backBtn setImage:backImage forState:UIControlStateNormal];
//    [backBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *colseItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = colseItem;
}

- (void)configColseItem {
    
    // 导航栏的关闭按钮
    UIButton *colseBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 30, 44)];
    [colseBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [colseBtn.titleLabel setFont:[UIFont systemFontOfSize:15.0]];
    [colseBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [colseBtn addTarget:self action:@selector(colseBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [colseBtn sizeToFit];
    
    UIBarButtonItem *colseItem = [[UIBarButtonItem alloc] initWithCustomView:colseBtn];
    NSMutableArray *newArr = [NSMutableArray arrayWithObjects:self.navigationItem.leftBarButtonItem,colseItem, nil];
    self.navigationItem.leftBarButtonItems = newArr;
}

#pragma mark - 普通按钮事件

// 返回按钮点击
- (void)backBtnPressed:(id)sender {

    if (self.wkWebView.canGoBack) {
        [self.wkWebView goBack];
        if (self.navigationItem.leftBarButtonItems.count == 1) {
            [self configColseItem];
        }
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// 关闭按钮点击
- (void)colseBtnPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)longPressed:(UILongPressGestureRecognizer*)recognizer
{
    NSLog(@"image url111");
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    __weak FDRWebViewController *weakSelf = self;
    CGPoint touchPoint = [recognizer locationInView:self.wkWebView];
    NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    
    [self.wkWebView evaluateJavaScript:js completionHandler:^(id _Nullable value, NSError* _Nullable error) {
        NSString *imageUrl = (NSString *)value;
        if (imageUrl.length == 0) {
            return;
        }
        NSLog(@"image url：%@",imageUrl);
//        if (([imageUrl containsString:@".png"] || [imageUrl containsString:@".jpg"]) && [imageUrl containsString:@"poster"]) {
//            recognizer.enabled = NO;
//            LCActionSheet *actionSheet = [[LCActionSheet alloc] initWithTitle:nil cancelButtonTitle:@"取消" clicked:^(LCActionSheet *actionSheet, NSInteger buttonIndex) {
//                recognizer.enabled = YES;
//                if (buttonIndex == 1) {
//                    [SVProgressHUD show];
//                    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//                    dispatch_async(concurrentQueue, ^{
//                        
//                        NSData *data = nil;
//                        NSString *fileName = [RNCachingURLProtocol cachePathForURLString:imageUrl];
//        
//                        RNCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
//                        
//                        if (cache) {
//                            NSLog(@"read from cache");
//                            data = cache.data;
//                        } else{
//                            NSLog(@"read from url");
//                            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
//                        }
//                        
//                        UIImage *image = [UIImage imageWithData:data];
//                        if (!image) {
//                            NSLog(@"read fail");
//                            return;
//                        }
//                        if (image) {
//                            UIImageWriteToSavedPhotosAlbum(image, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
//                        }
//                    });
//                }else if (buttonIndex == 2) {
//                    [SVProgressHUD show];
//                    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//                    dispatch_async(concurrentQueue, ^{
//                        NSData *data = nil;
//                        NSString *fileName = [RNCachingURLProtocol cachePathForURLString:imageUrl];
//                        
//                        RNCachedData *cache = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
//                        
//                        if (cache) {
//                            NSLog(@"read from cache");
//                            data = cache.data;
//                        } else{
//                            NSLog(@"read from url");
//                            data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
//                        }
//                        
//                        UIImage *image = [UIImage imageWithData:data];
//                        if (!image) {
//                            NSLog(@"read fail");
//                            return;
//                        }
//                        UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
//                        [pasteboard setImage:image];
//                        [SVProgressHUD showSuccessWithStatus:@"拷贝成功"];
//                    });
//
//                }
//            } otherButtonTitles:@"保存图片",@"拷贝", nil];
//            [actionSheet show];
//        }
    }];

}

#pragma mark LCActionSheetDelegate

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
//    if(error != NULL){
//        [SVProgressHUD showErrorWithStatus:@"保存图片失败"];
//    }else {
//        [SVProgressHUD showSuccessWithStatus:@"保存图片成功"];
//    }
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        otherGestureRecognizer.enabled = NO;
        otherGestureRecognizer.enabled = YES;
    }
    return NO;
}
#pragma mark - wkWebView代理
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
}

// 如果不添加这个，那么wkwebview跳转不了AppStore
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    
    if ([webView.URL.absoluteString hasPrefix:@"https://itunes.apple.com"]) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)wkWebView didFinishNavigation:(WKNavigation *)navigation {
    
    // 禁用用户选择
    [wkWebView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    // 禁用长按弹出框
    [wkWebView evaluateJavaScript:@"document.body.style.webkitTouchCallout='none';" completionHandler:nil];
    
    self.navigationItem.title = self.wkWebView.title;
    
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    //  js 里面的alert实现，如果不实现，网页的alert函数无效  ,
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
    

}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
     NSLog(@"%@----",message.name);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadJSData" object:nil];
    
    
    
}

- (void)reloadData{
    
    [self.wkWebView evaluateJavaScript:@"window.location.reload()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"%@ %@",response,error);
    }];
}

//- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
//    
//    NSLog(@"%@----",message.name);
//    if ([message.name isEqualToString: @"login"]) {
//        [[YSUserManager share] clearTokenUserID];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"tokenExpire" object:nil];
//    }
//    if ([message.name isEqualToString: @""]) {
//        [[YSUserManager share] clearTokenUserID];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"tokenExpire" object:nil];
//        [[BHBHTTPClinet sharedClient] httpRequest:API_account_logout parameters:nil result:^(NSDictionary *responseObject, YSError *error) {
//            if (!error) {
//                BaseModel *model = [BaseModel mj_objectWithKeyValues:responseObject];
//             
//                if (model.status == 0) {
//                    [[YSUserManager share] clearTokenUserID];
//                    [[YSUserManager share] clearDetail];
//                    [SVProgressHUD showSuccessWithStatus:model.message];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"tokenExpire" object:nil];
//                }else
//                {
//                    [SVProgressHUD showErrorWithStatus:model.message];
//                }
//            }
//        }];
//
//    }

//}

// 计算wkWebView进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.wkWebView && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        if (newprogress == 1) {
            self.progressView.hidden = YES;
            [self.progressView setProgress:0 animated:NO];
        }else {
            self.progressView.hidden = NO;
            [self.progressView setProgress:newprogress animated:YES];
        }
    }
}

// 记得取消监听
- (void)dealloc {
    
    [self.wkWebView removeObserver:self forKeyPath:@"estimatedProgress"];
}

#pragma mark - webView代理

// 计算webView进度条
- (void)setLoadCount:(NSUInteger)loadCount {
    
    _loadCount = loadCount;
    if (loadCount == 0) {
        self.progressView.hidden = YES;
        [self.progressView setProgress:0 animated:NO];
    }else {
        self.progressView.hidden = NO;
        CGFloat oldP = self.progressView.progress;
        CGFloat newP = (1.0 - oldP) / (loadCount + 1) + oldP;
        if (newP > 0.95) {
            newP = 0.95;
        }
        [self.progressView setProgress:newP animated:YES];
    }
}



@end
