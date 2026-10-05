#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <rootless.h>

static NSDictionary<NSString *, NSString *> *gDict;
static NSMutableSet<NSString *> *gLogged;
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
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *k = [s stringByTrimmingCharactersInSet:ws];
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
- (void)setText:(NSString *)t { %orig(tr(t)); }
- (void)setAttributedText:(NSAttributedString *)a {
    if (!a.length) { %orig; return; }
    NSString *n = tr(a.string);
    if ([n isEqualToString:a.string]) { %orig; return; }
    NSDictionary *at = [a attributesAtIndex:0 effectiveRange:NULL];
    %orig([[NSAttributedString alloc] initWithString:n attributes:at]);
}
%end

%hook UIButton
- (void)setTitle:(NSString *)t forState:(UIControlState)s { %orig(tr(t), s); }
%end

%hook UITextField
- (void)setPlaceholder:(NSString *)p { %orig(tr(p)); }
%end

%hook UIViewController
- (void)setTitle:(NSString *)t { %orig(tr(t)); }
%end

%hook UIAlertController
- (void)setTitle:(NSString *)t { %orig(tr(t)); }
- (void)setMessage:(NSString *)m { %orig(tr(m)); }
%end

%hook UIAlertAction
+ (instancetype)actionWithTitle:(NSString *)t style:(UIAlertActionStyle)st handler:(void (^)(UIAlertAction *))h {
    return %orig(tr(t), st, h);
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
