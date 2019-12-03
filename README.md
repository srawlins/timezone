# TimeZone

This package provides the [IANA time zone database] and time zone aware
`DateTime` class, [`TZDateTime`].

The current Time Zone database version is [2019c]. See [the announcement] for
details.


## Initialization

[`TimeZone`] objects require time zone data, so the first step is to load
one of our [time zone databases](#databases).

We provide three different APIs to load a database: one which is base64-encoded
into a Dart library, one for browsers, and one for standalone environments.

### Initialization from Dart library

This is the recommended way to initialize a time zone database for non-browser
environments. Each Dart libary found in `lib/data`, for example
`lib/data/latest.dart`, contains a single no-argument function,
`initializeTimeZones`.

```dart
import 'package:timezone/data/latest.dart';
void main() {
  initializeTimeZones();
}
```

### Initialization for browser environment

Import `package:timezone/browser.dart` library and run async function
`Future initializeTimeZone([String path])`.

```dart
import 'package:timezone/browser.dart';

Future<void> setup() async {
  await initializeTimeZone();
  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);
});
```

### Initialization for standalone environment

Import `package:timezone/standalone.dart` library and run async function
`Future initializeTimeZone([String path])`.

```dart
import 'package:timezone/standalone.dart';

Future<void> setup() async {
  await initializeTimeZone();
  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);
}
```

### Local Location

By default, when library is initialized, local location will be `UTC`.

To overwrite local location you can use `setLocalLocation(Location
location)` function.

```dart
Future<void> setup() async {
  await initializeTimeZone();
  final detroit = getLocation('America/Detroit');
  setLocalLocation(detroit);
}
```


## API

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

#### Get location by Olsen time zone ID

```dart
final detroit = getLocation('America/Detroit');
```

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
final timeInUtc = new DateTime.utc(1995, 1, 1);
final timeZone = detroit.timeZone(timeInUtc.millisecondsSinceEpoch);
```

### TimeZone aware DateTime

The `TZDateTime` class implements the `DateTime` interface from `dart:core`,
and contains information about location and time zone.

```dart
final date = new TZDateTime(detroit, 2014, 11, 17);
```

#### Converting DateTimes between time zones

To convert between time zones, just create a new `TZDateTime` object using
`from` constructor and pass `Location` and `DateTime` to the constructor.

```dart
final localTime = new DateTime(2010, 1, 1);
final detroitTime = new TZDateTime.from(time, detroit);
```

This constructor supports any objects that implement `DateTime` interface, so
you can pass a native `DateTime` object or our `TZDateTime`.

## <a name="databases"></a> Time Zone databases

We are using [IANA Time Zone Database](http://www.iana.org/time-zones)
to build our databases.

We are currently building three different database variants:

- default (doesn't contain deprecated and historical zones with some exceptions
  like US/Eastern). 361kb
- all (contains all data from the [IANA time zone database]). 443kb
- 2015-2025 (default database that contains historical data from 2015 until
  2025). 85kb

### Updating Time Zone databases

Script for updating Time Zone database, it will automatically download the
[IANA time zone database] and compile into our native format.

```sh
$ pub run tool/get -s 2014h
```

The argument `-s` is for specifying source version.

[2019c]: http://www.iana.org/time-zones/repository/releases/tzcode2019c.tar.gz
[IANA time zone database]: https://www.iana.org/time-zones
[`TZDateTime`]: https://pub.dartlang.org/documentation/timezone/latest/timezone.standalone/TZDateTime-class.html
[`TimeZone`]: https://pub.dartlang.org/documentation/timezone/latest/timezone.standalone/TimeZone-class.html
[the announcement]: https://mm.icann.org/pipermail/tz-announce/2019-September/000057.html
