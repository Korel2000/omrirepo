// AppDataHebrew — translates the AppData tweak UI into Hebrew.
// Rootless, SpringBoard + Preferences.

#import <UIKit/UIKit.h>

static NSDictionary<NSString *, NSString *> *gTranslations;      // exact keys
static NSSet<NSString *> *gGenericKeys;   // words that also appear in stock Settings
static BOOL gIsPreferences = NO;
static NSMutableDictionary<NSString *, NSNumber *> *gClassContextCache;

#pragma mark - Lookup

static NSString *ADHKeyFor(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) return nil;
    NSUInteger len = text.length;
    if (len == 0 || len > 40) return nil; // cheap early exit for the hot path
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (gTranslations[trimmed]) return trimmed;
    NSString *lower = trimmed.lowercaseString;
    for (NSString *k in gTranslations) {
        if ([k.lowercaseString isEqualToString:lower]) return k;
    }
    return nil;
}

// Is this view shown by an AppData view controller? (Used only in Settings,
// so generic words like "Light"/"Dark"/"Advanced" elsewhere in Settings stay untouched.)
static BOOL ADHControllerIsAppData(UIViewController *vc) {
    if (!vc) return NO;
    NSString *cls = NSStringFromClass([vc class]);
    NSNumber *cached = gClassContextCache[cls];
    if (cached) return cached.boolValue;
    NSString *path = [NSBundle bundleForClass:[vc class]].bundlePath ?: @"";
    BOOL match = [cls rangeOfString:@"appdata" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                 [path rangeOfString:@"appdata" options:NSCaseInsensitiveSearch].location != NSNotFound;
    gClassContextCache[cls] = @(match);
    return match;
}

static BOOL ADHViewInAppDataContext(UIView *view) {
    UIResponder *r = view;
    while (r) {
        if ([r isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)r;
            if (ADHControllerIsAppData(vc)) return YES;
            if ([vc isKindOfClass:[UINavigationController class]] &&
                ADHControllerIsAppData(((UINavigationController *)vc).topViewController)) return YES;
        }
        r = r.nextResponder;
    }
    return NO;
}

// Returns the Hebrew string for this label, or nil to leave it alone.
static NSString *ADHTranslationFor(NSString *text, UIView *view) {
    NSString *key = ADHKeyFor(text);
    if (!key) return nil;
    if (gIsPreferences && [gGenericKeys containsObject:key]) {
        if (!view.window || !ADHViewInAppDataContext(view)) return nil;
    }
    return gTranslations[key];
}

static NSAttributedString *ADHTranslateAttributed(NSAttributedString *a, UIView *view) {
    if (![a isKindOfClass:[NSAttributedString class]]) return nil;
    NSString *he = ADHTranslationFor(a.string, view);
    if (!he) return nil;
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithAttributedString:a];
    [m replaceCharactersInRange:NSMakeRange(0, m.length) withString:he]; // keeps first-run attributes
    return m;
}

#pragma mark - Hooks

%hook UILabel

- (void)setText:(NSString *)text {
    NSString *he = ADHTranslationFor(text, self);
    %orig(he ?: text);
}

- (void)setAttributedText:(NSAttributedString *)text {
    NSAttributedString *he = ADHTranslateAttributed(text, self);
    %orig(he ?: text);
}

// Generic words in Settings can only be judged once the label is on screen.
- (void)didMoveToWindow {
    %orig;
    if (!gIsPreferences || !self.window) return;
    NSString *cur = self.text;
    NSString *key = ADHKeyFor(cur);
    if (!key || ![gGenericKeys containsObject:key]) return;
    if (!ADHViewInAppDataContext(self)) return;
    if (self.attributedText.length) {
        NSAttributedString *he = ADHTranslateAttributed(self.attributedText, self);
        if (he) self.attributedText = he;
    } else {
        self.text = gTranslations[key];
    }
}

%end

#pragma mark - Init

%ctor {
    @autoreleasepool {
        gIsPreferences = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"];
        gClassContextCache = [NSMutableDictionary dictionary];

        gTranslations = @{
            @"Swipe Up": @"החלקה למעלה",
            @"Swipe Down": @"החלקה למטה",
            @"Icon Long Press": @"לחיצה ארוכה על האייקון",
            @"Menu 3D Touch": @"תפריט 3D Touch",
            @"Remove Separator": @"הסתרת מפרידים",
            @"Hide Separators": @"הסתרת מפרידים",
            @"Auto Clear": @"ניקוי מטמון אוטומטי",
            @"Running Indicator": @"מחוון אפליקציה פועלת",
            @"Indicator Color": @"צבע המחוון",
            @"Layout": @"פריסה",
            @"Hidden Apps": @"אפליקציות מוסתרות",
            @"Open Path In": @"פתיחת נתיב באמצעות",
            @"Appearance": @"מראה תצוגה",
            @"Theme Style": @"מראה תצוגה",
            @"Light": @"בהיר",
            @"Dark": @"כהה",
            @"Automatic": @"אוטומטי",
            @"Themes": @"ערכות נושא",
            @"Clear Cache": @"ניקוי מטמון",
            @"Clear Caches": @"ניקוי מטמון",
            @"Clear Data": @"מחיקת נתונים",
            @"Reset Data": @"איפוס נתונים",
            @"Reset Perms": @"איפוס הרשאות",
            @"Reset Permissions": @"איפוס הרשאות",
            @"Downgrade": @"שנמוך",
            @"Downgrade App": @"שנמוך גרסה",
            @"Uninstall": @"הסרת התקנה",
            @"Delete app": @"מחיקת אפליקציה",
            @"Block Launch": @"חסימת הפעלה",
            @"Block Open": @"חסימת פתיחה",
            @"Block Notif": @"חסימת התראות",
            @"Block Notifs": @"חסימת התראות",
            @"Mute Notif": @"השתקת התראות",
            @"Mute App": @"השתקת אפליקציה",
            @"Keep Awake": @"השארת מסך דולק",
            @"App Lock": @"נעילת אפליקציה",
            @"Startup Brightness": @"בהירות בהפעלה",
            @"Open in Filza": @"פתח ב-Filza",
            @"Copy Path": @"העתק נתיב",
            @"Copy Identifier": @"העתק מזהה (Bundle ID)",
            @"Bundle Data": @"נתוני חבילה",
            @"App Groups": @"קבוצות אפליקציה",
            @"Advanced": @"מתקדם",
            @"More Info": @"מידע נוסף",
            @"Respring": @"ריספרינג",
            @"Shut Down": @"כיבוי",
            @"Userspace Reboot": @"אתחול מרחב משתמש",
        };

        // Words that also appear in stock Settings pages: in Preferences these are
        // translated only inside AppData's own screens.
        gGenericKeys = [NSSet setWithArray:@[
            @"Layout", @"Appearance", @"Theme Style", @"Light", @"Dark", @"Automatic",
            @"Themes", @"Advanced", @"More Info", @"Shut Down", @"Hidden Apps",
            @"Uninstall", @"Downgrade",
        ]];

        %init;
    }
}
