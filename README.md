# TimeZone

This package provides the [IANA time zone database] and time zone aware
`DateTime` class, [`TZDateTime`].

The current time zone database version is [2024a]. See [the announcement] for
details.

You can update to the current IANA time zone database by running
`tool/refresh.sh`.


## Initialization

[`TimeZone`] objects require time zone data, so the first step is to load
one of our [time zone databases](#databases).

We provide three different APIs to load a database: one which is embedded
into a Dart library, one for browsers, and one for standalone environments.

### Database variants

We offer three different variants of the IANA database:

- **default**: doesn't contain deprecated and historical zones with some
  exceptions like "US/Eastern" and "Etc/UTC"; this is about 75% the size of the
  **all** database.
- **all**: contains all data from the [IANA time zone database].
- **10y**: default database truncated to contain historical data from 5 years 
  ago until 5 years in the future; this database is about 25% the size of the
  default database.

### Initialization from Flutter asset

This is the recommended way for Flutter. It bundles the timezone data as an
asset and loads asynchronously. It works on all Flutter platforms including
web.

Include the timezone data as an asset in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - packages/timezone/data/latest.tzf
    # or
    # - packages/timezone/data/latest_all.tzf
    # or
    # - packages/timezone/data/latest_10y.tzf
```

Load asset with `rootBundle` or `DefaultAssetBundle.of(context)`, create a
`Uint8List` view and call `initializeDatabase`.
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final path = 'packages/timezone/data/latest.tzf';
  // or
  // final path = 'packages/timezone/data/latest_all.tzf';
  // or
  // final path = 'packages/timezone/data/latest_10y.tzf';

  tz.initializeDatabase(Uint8List.sublistView(await rootBundle.load(path)));

  runApp(MyApp());
}
```

### Initialization from Dart library

This is the recommended way to initialize a time zone database for non-browser
environments. Each Dart library found in `lib/data`, for example
`lib/data/latest.dart`, contains a single no-argument function,
`initializeTimeZones`.

```dart
import 'package:timezone/data/latest.dart' as tz;
void main() {
  tz.initializeTimeZones();
}
```

This method works in all environments including Flutter. It works on the web
but is not recommended. On the web, page loads slower because embedded timezone
data increases JavaScript output. Other methods load timezone data
asynchronously, they should be used in browser environments.

To initialize the **all** database variant, `import
'package:timezone/data/latest_all.dart'`. To initialize the **10y**
database variant, `import 'package:timezone/data/latest_10y.dart'`.

### Initialization for browser environment

Import `package:timezone/browser.dart` library and run async function
`Future initializeTimeZone([String path])`.

```dart
import 'package:timezone/browser.dart' as tz;

Future<void> setup() async {
  await tz.initializeTimeZone();
  var detroit = tz.getLocation('America/Detroit');
  var now = tz.TZDateTime.now(detroit);
}
```

To initialize the **all** database variant, call
`initializeTimeZone('packages/timezone/data/latest_all.tzf')`. To initialize
the **10y** database variant, call
`initializeTimeZone('packages/timezone/data/latest_10y.tzf')`.

### Initialization for standalone environment

Import `package:timezone/standalone.dart` library and run async function
`Future initializeTimeZone([String path])`.

```dart
import 'package:timezone/standalone.dart' as tz;

Future<void> setup() async {
  await tz.initializeTimeZone();
  var detroit = tz.getLocation('America/Detroit');
  var now = tz.TZDateTime.now(detroit);
}
```

Note: This method likely will not work in a Flutter environment.

To initialize the **all** database variant, call
`initializeTimeZone('data/latest_all.tzf')`. To initialize the **10y**
database variant, call `initializeTimeZone('data/latest_10y.tzf')`.

### Local Location

By default, when library is initialized, local location will be `UTC`.

To overwrite local location you can use `setLocalLocation(Location
location)` function.

```dart
Future<void> setup() async {
  await tz.initializeTimeZone();
  var detroit = tz.getLocation('America/Detroit');
  tz.setLocalLocation(detroit);
}
```


## API

### Library Namespace

The public interfaces expose several top-level functions. It is recommended
then to import the libraries with a prefix (the prefix `tz` is common), or to
import specific members via a `show` clause.

### Location

> Each location in the database represents a national region where all
> clocks keeping local time have agreed since 1970. Locations are
> identified by continent or ocean and then by the name of the
> location, which is typically the largest city within the region. For
> example, America/New_York represents most of the US eastern time
> zone; America/Phoenix represents most of Arizona, which uses
> mountain time without daylight saving time (DST); America/Detroit
> represents most of Michigan, which uses eastern time but with
> different DST rules in 1975; and other entries represent smaller
> regions like Starke County, Indiana, which switched from central to
> eastern time in 1991 and switched back in 2006.
>
> [The tz database](https://www.iana.org/time-zones)

#### Get location by tz database/Olson name

```dart
final detroit = tz.getLocation('America/Detroit');
```

See [Wikipedia list] for more database entry names.

We don't provide any functions to get locations by time zone abbreviations
because of the ambiguities.

> Alphabetic time zone abbreviations should not be used as unique identifiers
> for UTC offsets as they are ambiguous in practice. For example, "EST" denotes
> 5 hours behind UTC in English-speaking North America, but it denotes 10 or 11
> hours ahead of UTC in Australia; and French-speaking North Americans prefer
> "HNE" to "EST".
>
> [The tz database](https://www.iana.org/time-zones)

### TimeZone

TimeZone objects represents time zone and contains offset, DST flag, and name
in the abbreviated form.

```dart
var timeInUtc = DateTime.utc(1995, 1, 1);
var timeZone = detroit.timeZone(timeInUtc.millisecondsSinceEpoch);
```

### TimeZone aware DateTime

The `TZDateTime` class implements the `DateTime` interface from `dart:core`,
and contains information about location and time zone.

```dart
var date = tz.TZDateTime(detroit, 2014, 11, 17);
```

#### Converting DateTimes between time zones

To convert between time zones, just create a new `TZDateTime` object using
`from` constructor and pass `Location` and `DateTime` to the constructor.

```dart
var localTime = tz.DateTime(2010, 1, 1);
var detroitTime = tz.TZDateTime.from(localTime, detroit);
```

This constructor supports any objects that implement `DateTime` interface, so
you can pass a native `DateTime` object or our `TZDateTime`.

### Listing known time zones

After initializing the time zone database, the `timeZoneDatabase` top-level
member contains all of the known time zones. Examples:

```dart
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones();
  var locations = tz.timeZoneDatabase.locations;
  print(locations.length); // => 429
  print(locations.keys.first); // => "Africa/Abidjan"
  print(locations.keys.last); // => "US/Pacific"
}
```

## <a name="databases"></a> Time Zone databases

We are using [IANA Time Zone Database](http://www.iana.org/time-zones)
to build our databases.

We currently build three different database variants:

- default (doesn't contain deprecated and historical zones with some exceptions
  like US/Eastern). 361kb
- all (contains all data from the [IANA time zone database]). 443kb
- 10y (default database that contains historical data from the last and future 5
  years). 85kb

### Updating Time Zone databases

Script for updating Time Zone database, it will automatically download the
[IANA time zone database] and compile into our native format.

```sh
$ chmod +x tool/refresh.sh
$ tool/refresh.sh
```

Note, on Windows, you may need to follow [these
steps](https://github.com/srawlins/timezone/issues/60#issuecomment-638411716)
which use WSL.

[2024a]: https://data.iana.org/time-zones/releases/tzdb-2024a.tar.lz
[IANA time zone database]: https://www.iana.org/time-zones
[Wikipedia list]: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
[`TZDateTime`]: https://pub.dartlang.org/documentation/timezone/latest/timezone.standalone/TZDateTime-class.html
[`TimeZone`]: https://pub.dartlang.org/documentation/timezone/latest/timezone.standalone/TimeZone-class.html
[the announcement]: https://mm.icann.org/pipermail/tz/2024-February.txt
