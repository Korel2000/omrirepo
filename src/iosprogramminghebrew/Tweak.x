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
}
- (void)setMessage:(NSString *)m {
    NSString *n = tr(m);
    %orig(n);
}
%end

%ctor {
    @autoreleasepool {
        gLogged = [NSMutableSet set];
        NSString *path = ROOT_PATH_NS(@"/Library/Application Support/IOSProgrammingHebrew/he.plist");
        gDict = [NSDictionary dictionaryWithContentsOfFile:path] ?: @{};
        %init;
    }
}
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
}
- (void)setMessage:(NSString *)m {
    NSString *n = tr(m);
    %orig(n);
}
%end

%ctor {
    @autoreleasepool {
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        gActive = (bid.length > 0 && ![bid hasPrefix:@"com.apple."]);
        gLogged = [NSMutableSet set];
        gDict = [@{
            @"Language": @"שפה", @"Skills": @"מיומנויות", @"App": @"אפליקציה",
            @"Rate": @"דרג", @"Test": @"מבחן", @"Honor": @"הישגים", @"Unlock": @"פתיחה",
            @"The Basics": @"יסודות", @"Data Types": @"סוגי נתונים",
            @"Control Flow": @"בקרת זרימה", @"Function": @"פונקציות",
            @"Class": @"מחלקות", @"Extension": @"הרחבות", @"Foundation": @"Foundation",
            @"Advanced": @"מתקדם", @"Project": @"פרויקט"
        } mutableCopy];
        NSString *path = ROOT_PATH_NS(@"/Library/Application Support/IOSProgrammingHebrew/he.plist");
        NSDictionary *extra = [NSDictionary dictionaryWithContentsOfFile:path];
        if (extra) [gDict addEntriesFromDictionary:extra];
        %init;
    }
}
__attribute__((constructor)) static void ipbDiag(void) {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        static BOOL shown = NO;
        if (shown) return;
        shown = YES;
        NSString *msg = [NSString stringWithFormat:@"bundle: %@\nactive: %d\nwords: %lu", [NSBundle mainBundle].bundleIdentifier, gActive, (unsigned long)gDict.count];
        UIWindow *w = nil;
        for (UIScene *sc in [UIApplication sharedApplication].connectedScenes) {
            if ([sc isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *x in ((UIWindowScene *)sc).windows) {
                    if (x.isKeyWindow) w = x;
                }
            }
        }
        UIViewController *vc = w.rootViewController;
        while (vc.presentedViewController) vc = vc.presentedViewController;
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"IOSProgHebrew" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [vc presentViewController:a animated:YES completion:nil];
    }];
}
