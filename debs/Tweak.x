// AppDataHebrew — Hebrew translation for the AppData tweak UI.
// Translated by Omri Guez. Rootless, SpringBoard + Preferences.

#import <UIKit/UIKit.h>

#define ADH_CREDIT @"תרגום לעברית: Omri Guez"
#define ADH_FOOTER_FIRST_LINE @"Swipe up/down or 3D Touch to open."

static NSDictionary<NSString *, NSString *> *gTranslations; // exact keys
static NSDictionary<NSString *, NSString *> *gLowerToKey;   // lowercase -> exact key
static NSSet<NSString *> *gGenericKeys;   // words that also appear in other Settings pages
static BOOL gIsPreferences = NO;
static NSMutableDictionary<NSString *, NSNumber *> *gClassContextCache;

#pragma mark - Lookup

static NSString *ADHKeyForLine(NSString *line) {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;
    if (gTranslations[trimmed]) return trimmed;
    return gLowerToKey[trimmed.lowercaseString];
}

static NSString *ADHKeyFor(NSString *text) {
    if (![text isKindOfClass:[NSString class]]) return nil;
    NSUInteger len = text.length;
    if (len == 0 || len > 60) return nil; // cheap early exit for the hot path
    return ADHKeyForLine(text);
}

// Multi-line footers: translate line by line; add the credit under AppData's main footer.
static NSString *ADHTranslateMultiline(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length > 600 ||
        [text rangeOfString:@"\n"].location == NSNotFound) return nil;
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *out = [NSMutableArray arrayWithCapacity:lines.count + 2];
    BOOL changed = NO, isMainFooter = NO;
    for (NSString *line in lines) {
        NSString *key = ADHKeyForLine(line);
        if (key) {
            [out addObject:gTranslations[key]];
            changed = YES;
            if ([key isEqualToString:ADH_FOOTER_FIRST_LINE]) isMainFooter = YES;
        } else {
            [out addObject:line];
        }
    }
    if (!changed) return nil;
    if (isMainFooter) { [out addObject:@""]; [out addObject:ADH_CREDIT]; }
    return [out componentsJoinedByString:@"\n"];
}

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

static NSString *ADHTranslationFor(NSString *text, UIView *view) {
    NSString *key = ADHKeyFor(text);
    if (!key) return ADHTranslateMultiline(text);
    if (gIsPreferences && [gGenericKeys containsObject:key]) {
        if (!view || !view.window || !ADHViewInAppDataContext(view)) return nil;
    }
    return gTranslations[key];
}

static NSAttributedString *ADHTranslateAttributed(NSAttributedString *a, UIView *view) {
    if (![a isKindOfClass:[NSAttributedString class]] || a.length == 0) return nil;
    NSString *he = ADHTranslationFor(a.string, view);
    if (!he) return nil;
    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithAttributedString:a];
    [m replaceCharactersInRange:NSMakeRange(0, m.length) withString:he];
    return m;
}

// No-view translation for titles owned by a known AppData controller.
static NSString *ADHDirect(NSString *text) {
    NSString *key = ADHKeyFor(text);
    return key ? gTranslations[key] : nil;
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

- (void)didMoveToWindow {
    %orig;
    if (!gIsPreferences || !self.window) return;
    NSString *key = ADHKeyFor(self.text);
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

// Navigation-bar title and bar buttons ("Layout", "Default") on AppData screens.
static void ADHFixNavigationItem(UIViewController *vc) {
    if (!gIsPreferences || !ADHControllerIsAppData(vc)) return;
    UINavigationItem *item = vc.navigationItem;
    NSString *he = ADHDirect(item.title ?: vc.title);
    if (he) item.title = he;
    NSMutableArray<UIBarButtonItem *> *buttons = [NSMutableArray array];
    if (item.leftBarButtonItems) [buttons addObjectsFromArray:item.leftBarButtonItems];
    if (item.rightBarButtonItems) [buttons addObjectsFromArray:item.rightBarButtonItems];
    for (UIBarButtonItem *b in buttons) {
        NSString *bt = ADHDirect(b.title);
        if (bt) b.title = bt;
    }
}

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    ADHFixNavigationItem(self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    ADHFixNavigationItem(self);
}

%end

#pragma mark - Init

%ctor {
    @autoreleasepool {
        gIsPreferences = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"];
        gClassContextCache = [NSMutableDictionary dictionary];

        gTranslations = @{
            // Original dictionary
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

            // Added from screenshots
            @"3D Touch Menu": @"תפריט 3D Touch",
            @"Manage app data on the Home Screen.": @"ניהול נתוני אפליקציות ממסך הבית.",
            @"Settings": @"הגדרות",
            @"Import": @"ייבוא",
            @"None": @"ללא",
            @"语言 / Language": @"שפה / Language",
            @"Features & Guide": @"תכונות ומדריך",
            @"查看已开启屏蔽自动更新的应用": @"אפליקציות עם חסימת עדכונים",
            @"BG Apps": @"אפליקציות ברקע",
            @"Redirects": @"הפניות",
            @"Guide": @"מדריך",
            @"Developer": @"מפתח",
            @"Source Code": @"קוד מקור",
            @"Modified By": @"שונה על ידי",
            @"Open Source": @"קוד פתוח",
            @"Default": @"ברירת מחדל",
            @"Main Buttons (Max 6)": @"כפתורים ראשיים (עד 6)",
            @"More List": @"רשימה נוספת",
            @"禁音应用通知": @"השתקת התראות אפליקציה",
            @"No Uninstall": @"מניעת הסרה",
            @"Block App Update": @"חסימת עדכוני אפליקציה",
            @"Badge": @"תג",
            @"Actions": @"פעולות",
            @"Delete": @"מחיקה",
            @"System": @"מערכת",
            @"Containers": @"תיקיות",
            @"Bundle": @"חבילה",
            @"Data": @"נתונים",

            // Footer lines
            ADH_FOOTER_FIRST_LINE: @"החלקה למעלה/למטה או 3D Touch לפתיחה.",
            @"Auto-clear applies to all.": @"ניקוי אוטומטי חל על כל האפליקציות.",
            @"Hidden apps need respring.": @"הסתרת אפליקציות דורשת ריספרינג.",
            @"Import zip themes named by Bundle ID.": @"ייבוא ערכות נושא כקובץ zip בשם ה-Bundle ID.",
            @"Running indicator adds a dot.": @"מחוון אפליקציה פועלת מוסיף נקודה.",
        };

        NSMutableDictionary *lower = [NSMutableDictionary dictionaryWithCapacity:gTranslations.count];
        for (NSString *k in gTranslations) lower[k.lowercaseString] = k;
        gLowerToKey = lower;

        // Words that also appear on other Settings pages: translated only inside AppData's screens.
        gGenericKeys = [NSSet setWithArray:@[
            @"Layout", @"Appearance", @"Theme Style", @"Light", @"Dark", @"Automatic",
            @"Themes", @"Advanced", @"More Info", @"Shut Down", @"Hidden Apps",
            @"Uninstall", @"Downgrade", @"Settings", @"Import", @"None", @"Guide",
            @"Developer", @"Source Code", @"Open Source", @"Default", @"Badge",
            @"Actions", @"Delete", @"System", @"Containers", @"Bundle", @"Data",
            @"Redirects",
        ]];

        %init;
    }
}
