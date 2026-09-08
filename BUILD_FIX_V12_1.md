# V12.1 Build Fix

- Downgraded `flutter_timezone` from `^5.1.0` to `^4.1.1` for Flutter 3.24.5 compatibility.
- Updated timezone initialization for the v4 API (`getLocalTimezone()` returns a String).
- Keeps Java 17 Android configuration required by flutter_timezone 4.x.

This fixes the dependency solver error caused by Flutter 3.24.5 pinning `meta` 1.15.0 while flutter_timezone 5.x requires meta >=1.16.0.
