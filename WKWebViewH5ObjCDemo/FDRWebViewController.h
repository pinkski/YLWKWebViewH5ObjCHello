


#import <UIKit/UIKit.h>

@interface FDRWebViewController : UIViewController

@property (strong, nonatomic) NSURL *homeUrl;

/** 传入控制器、url、标题 */
+ (void)showWithContro:(UIViewController *)contro withUrlStr:(NSString *)urlStr withTitle:(NSString *)title;

@end
