# iOS-Programming Hebrew (עברית)

טוויק rootless שמתרגם בזמן ריצה את הממשק של iOS-Programming.dylib ו-blatantsPatch.dylib לעברית.
הוא פעיל רק בתהליכים שבהם אחת הספריות נטענה, ולא נוגע בקבצים שלהן.

## איך מוסיפים תרגומים
1. התקן את ה-deb, פתח את האפליקציה שבה הטוויק מופיע.
2. פתח Console / `idevicesyslog` וסנן לפי `IOSProgHebrew`. כל טקסט שלא תורגם מופיע כשורה `MISSING: <טקסט>`.
3. הוסף את הטקסט כמפתח ואת התרגום כערך ב-`/var/jb/Library/Application Support/IOSProgrammingHebrew/he.plist`.
4. סגור את האפליקציה ופתח מחדש.

התאמה היא לטקסט מדויק בלבד, ולכן טקסטים עם מספרים משתנים צריכים הוספה פרטנית.
