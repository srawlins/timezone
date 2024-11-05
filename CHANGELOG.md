# 0.10.0

- Update time zone-updating script to use `rearguard.zi`.
- Convert `browser.dart` to use `package:http` instead of `dart:html` for HTTP
  requests.
- Time zone database updated to 2024b. For your convenience here is the
  announcement for [2024b].

[2024b]: https://lists.iana.org/hyperkitty/list/tz-announce@iana.org/thread/IZ7AO6WRE3W3TWBL5IR6PMQUL433BQIE/

# 0.9.4

- Support cross-isolate issues by overriding `hashCode` and `operator ==` on
  class `Location`. (see #147)
- Fix incorrect DST transition. (see #166)

# 0.9.3

- Time zone database updated to 2024a. For your convenience here are the
  announcements for [2023d], [2024a].

[2023d]: https://mm.icann.org/pipermail/tz-announce/2023-December.txt
[2024a]: https://mm.icann.org/pipermail/tz-announce/2024-February.txt


# 0.9.2

- Time zone database updated to 2023c. For your convenience here are the
  announcements for [2023a], [2023b], [2023c].

[2023a]: http://mm.icann.org/pipermail/tz-announce/2023-March/000077.html
[2023b]: http://mm.icann.org/pipermail/tz-announce/2023-March/000078.html
[2023c]: http://mm.icann.org/pipermail/tz-announce/2023-March/000079.html

# 0.9.1

- Time zone database updated to 2022g. For your convenience here are the
  announcements for [2022d], [2022e], [2022f], [2022g].

[2022d]: http://mm.icann.org/pipermail/tz-announce/2022-September/000073.html
[2022e]: http://mm.icann.org/pipermail/tz-announce/2022-October/000074.html
[2022f]: http://mm.icann.org/pipermail/tz-announce/2022-October/000075.html
[2022g]: http://mm.icann.org/pipermail/tz-announce/2022-November/000076.html

# 0.9.0

- Time zone database updated to 2022c. For your convenience here are the
  announcements for [2022a], [2022b], [2022c].
- Removed named database files in `lib/data` (for example, `lib/data/2021e.tzf`).
  The only supported database files are all now named `latest_*`.

[2022a]: http://mm.icann.org/pipermail/tz-announce/2022-March/000070.html
[2022b]: http://mm.icann.org/pipermail/tz-announce/2022-August/000071.html
[2022c]: http://mm.icann.org/pipermail/tz-announce/2022-August/000072.html

# 0.8.1

- Time zone database updated to 2021e. For your convenience here are the
  announcements for [2021b], [2021c], [2021d], [2021e].
- Fixed encoding script to not skip a few missing time zones.

[2021b]: http://mm.icann.org/pipermail/tz-announce/2021-September/000066.html
[2021c]: http://mm.icann.org/pipermail/tz-announce/2021-October/000067.html
[2021d]: http://mm.icann.org/pipermail/tz-announce/2021-October/000068.html
[2021e]: http://mm.icann.org/pipermail/tz-announce/2021-October/000069.html

# 0.8.0

- Time zone database updated to 2021a. For your convenience here is the
  announcement for [2021a].
- Time zone databases encoded with UTF-16 instead of base64.
- **Breaking change**: Remove `tool/encode.dart` in favor of
  `tool/encode_dart.dart`.

[2021a]: https://mm.icann.org/pipermail/tz-announce/2021-January/000065.html


# 0.7.0

- **Breaking change**: Change some of TimeZone's constructor parameters to be
  named instead of positional.
- **Breaking change**: Rename `TimeZone.abbr` to `TimeZone.abbreviation`.
- Deprecate `LocationDatabase.isEmpty` in favor of
  `LocationDatabase.isInitialized`.
- Removed `new` usage from examples and fixed a typo in the `TZDateTime.from`
  example.
- Migrate to Dart's null safety language feature.

# 0.6.1

- Updated the `get` script (now `encode_tzf`) to work with a `zoneinfo`
  directory (as created by the `zic` tool) as input. Fetching and compiling this
  directory is now done by a bash script (`refresh.sh`) using standard tools.

  This allows pointing the tool at a custom `zoneinfo` directory.

# 0.6.0

- Stopping internal versioning of time zone data. Only the latest data will be
  included, as there is no use case for using an outdated version.
- Renaming the `_2015_2025` database to `_10y` for it to have a stable name.
  In the past `latest_2010-2020.tzf` had to be renamed to
  `latest_2015-2025.tzf`.

# 0.5.9

- Time zone database updated to 2020d. For your convenience here is the
  announcement for [2020d].

[2020d]: https://mm.icann.org/pipermail/tz-announce/2020-October/000062.html

# 0.5.8

- Time zone database updated to 2020b. For your convenience here is the
  announcement for [2020b].

[2020b]: https://mm.icann.org/pipermail/tz-announce/2020-October/000059.html

# 0.5.7

- Time zone database updated to 2020a. For your convenience here is the
  announcement for [2020a].
- Earlier null checking on some TZDateTime constructor arguments.
- Many internal changes; should not affect API.

[2020a]: http://mm.icann.org/pipermail/tz-announce/2020-April/000058.html

# 0.5.6

- Time zone database updated to 2019c. For your convenience here is the
  announcement for [2019c].
- Dart-importable databases made available in `lib/data`. README.md has more
  details.

[2019c]: http://mm.icann.org/pipermail/tz-announce/2019-September/000057.html

# 0.5.5

- Time zone database updated to 2019b. For your convenience here is the
  announcement for [2019b].
- Convenience database symlinks added for convenience at
  - `lib/data/latest.tzf`
  - `lib/data/latest_2015-2025.tzf`
  - `lib/data/latest_all.tzf`

[2019b]: http://mm.icann.org/pipermail/tz-announce/2019-July/000056.html

# 0.5.4

- TZDateTime.utc is accessible before time zone database is initialized (thanks
  @jsmarr).
- Fix dropping microseconds when creating TZDateTime (thanks @jsmarr).

# 0.5.3

- Time zone database updated to 2019a. For your convenience here is the
  announcement for [2019a].

[2019a]: http://mm.icann.org/pipermail/tz-announce/2019-March/000055.html

# 0.5.2

- Time zone database updated to 2018i. For your convenience here are the
  announcements for [2018h] and [2018i].

[2018h]: http://mm.icann.org/pipermail/tz-announce/2018-December/000053.html
[2018i]: http://mm.icann.org/pipermail/tz-announce/2018-December/000054.html

# 0.5.1

- Time zone database updated to 2018g. For your convenience here are the
  announcements for [2018d], [2018e], [2018f], and [2018g].

[2018d]: http://mm.icann.org/pipermail/tz-announce/2018-March/000049.html
[2018e]: http://mm.icann.org/pipermail/tz-announce/2018-May/000050.html
[2018f]: http://mm.icann.org/pipermail/tz-announce/2018-October/000051.html
[2018g]: http://mm.icann.org/pipermail/tz-announce/2018-October/000052.html

# 0.5.0

- Support a package-directory-free environment. In Dart 1.19, timezone is now
  compatible with `pub get --no-packages-dir`.
- **Breaking:** Remove initializeTimeZoneSync method; it is incompatible with
  the async method for resolving package URIs.
- Fix all strong mode _errors_ (thanks @har79).
- Add microsecond support (thanks @har79).
- Improve interaction between TZDateTime and native DateTime (thanks @har79).
- Fix TimeZone's `==` (thanks @har79).
- Many new dartdoc comments (thanks @har79).
- Fix for calling `new TZDateTime.from()` with a non-UTC DateTime object
  (thanks @tomaine2002).
- Support Dart 2.
- Time zone database updated to 2018c. For your convenience here are the
  announcements for [2015c], [2015d], [2015e], [2015f], [2015g], [2016a],
  [2016b], [2016c], [2016d], [2016e], [2016f], [2016g], [2016h], [2016i],
  [2017a], [2017b], [2017c], and [2018c].

[2015c]: http://mm.icann.org/pipermail/tz-announce/2015-April/000030.html
[2015d]: http://mm.icann.org/pipermail/tz-announce/2015-April/000031.html
[2015e]: http://mm.icann.org/pipermail/tz-announce/2015-June/000032.html
[2015f]: http://mm.icann.org/pipermail/tz-announce/2015-August/000033.html
[2015g]: http://mm.icann.org/pipermail/tz-announce/2015-October/000034.html
[2016a]: http://mm.icann.org/pipermail/tz-announce/2016-January/000035.html
[2016b]: http://mm.icann.org/pipermail/tz-announce/2016-March/000036.html
[2016c]: http://mm.icann.org/pipermail/tz-announce/2016-March/000037.html
[2016d]: http://mm.icann.org/pipermail/tz-announce/2016-April/000038.html
[2016e]: http://mm.icann.org/pipermail/tz-announce/2016-June/000039.html
[2016f]: http://mm.icann.org/pipermail/tz-announce/2016-July/000040.html
[2016g]: http://mm.icann.org/pipermail/tz-announce/2016-September/000041.html
[2016h]: http://mm.icann.org/pipermail/tz-announce/2016-October/000042.html
[2016i]: http://mm.icann.org/pipermail/tz-announce/2016-November/000043.html
[2017a]: http://mm.icann.org/pipermail/tz-announce/2017-February/000045.html
[2017b]: http://mm.icann.org/pipermail/tz-announce/2017-March/000046.html
[2017c]: http://mm.icann.org/pipermail/tz-announce/2017-October/000047.html
[2018c]: http://mm.icann.org/pipermail/tz-announce/2018-January/000048.html

# 0.4.3

- Fix Dart 1.14 incompatibility further.

# 0.4.2

- Bad pub publish. Ignore.

# 0.4.1

- Fix Dart 1.14 incompatibility with packageRoot returning null.

# 0.4.0

- Remove usage of tuple package.
- Upgrade unittest package to test.
- Fix database URL for "latest" database.
- Add tool/dartfmt for formatting source.

# 0.3.1

- `generate_data_subset` script is removed. It will be available as a
  separate package.

# 0.3.0

- Time zone database updated to 2015b.
- Removed local location detection heuristics (didn't worked properly).
  Local location is initialized with UTC location by default, use
  `setLocalLocation` to change local location.
- Time zone database format is changed; data is aligned.

# 0.2.5

- Fixed bug with String formatting (invalid offsets for minutes).

# 0.2.4

- Fixed bug with Calendar-type constructor.

# 0.2.3

- Added `initializeTimeZoneSync` function for standalone environments.
- Fixed bug with script path on Windows.

# 0.2.2

- TimeZone database updated to "2014j".
- "args" and "path" moved from dev dependencies to dependencies.

# 0.2.1

- `tzfile` library renamed to `tzdata`.
- Added `zone1970.tab` parser to `tzdata` library.
- Removed `package:collection` dependency.
