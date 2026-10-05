#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#if __has_include(<rootless.h>)
#import <rootless.h>
#else
#define ROOT_PATH_NS(path) (@"/var/jb" path)
#endif

static NSDictionary *gDict;
static NSMutableSet *gLogged;
static BOOL gActive = NO;

static BOOL targetLoaded(void) {
    if (gActive) return YES;
    uint32_t n = _dyld_image_count();
    for (uint32_t i = 0; i < n; i++) {
        const char *p = _dyld_get_image_name(i);
        if (p && (strstr(p, "iOS-Programming.dylib") || strstr(p, "blatantsPatch.dylib"))) {
            gActive = YES;
            break;
        }
    }
    return gActive;
}

static NSString *tr(NSString *s) {
    if (![s isKindOfClass:[NSString class]] || s.length == 0 || !targetLoaded()) return s;
    NSString *k = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *h = gDict[k];
    if (h.length) return h;
    if ([k rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != NSNotFound) {
        @synchronized (gLogged) {
            if (![gLogged containsObject:k]) {
                [gLogged addObject:k];
                NSLog(@"[IOSProgHebrew] MISSING: %@", k);
            }
        }
    }
    return s;
}

%hook UILabel
- (void)setText:(NSString *)t {
    NSString *n = tr(t);
    %orig(n);
}
%end

%hook UIButton
- (void)setTitle:(NSString *)t forState:(UIControlState)s {
    NSString *n = tr(t);
    %orig(n, s);
}
%end

%hook UITextField
- (void)setPlaceholder:(NSString *)p {
    NSString *n = tr(p);
    %orig(n);
}
%end

%hook UIViewController
- (void)setTitle:(NSString *)t {
    NSString *n = tr(t);
    %orig(n);
}
%end

%hook UIAlertController
- (void)setTitle:(NSString *)t {
    NSString *n = tr(t);
    %orig(n);
}​​​​​​​​​​​​​​​​
