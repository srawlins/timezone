---
name: Missing Timezone Report
about: Report a timezone that appears to be missing from the library
title: "[Missing Timezone] "
labels: 'type: missing-timezone'
assignees: ''
---

### ⚠️ IMPORTANT: Have you tried `latest_all.dart`?
The standard `latest.dart` library only contains **canonical** (current) timezone names. Many requested timezones (like `Europe/Kiev`) are **deprecated or legacy names** in the [IANA database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

**Please check if your timezone is available by importing the "all" library instead:**
```dart
import 'package:timezone/data/latest_all.dart' as tz;
```