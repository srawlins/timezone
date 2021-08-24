import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  await tz.TimezoneManager.instance
      .initializeTimezoneConfiguration(tz.DatabaseVariant.latestAll);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Zone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Time Zone'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final tz.Location detroitLocation = tz.getLocation('America/Detroit');
  final tz.Location argentinaLocation =
      tz.getLocation('America/Argentina/Buenos_Aires');
  final tz.Location hongKongLocation = tz.getLocation('Asia/Hong_Kong');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Time Zones', style: Theme.of(context).textTheme.headline6),
            SizedBox(
              height: 12,
            ),
            Text(
              'Date on Detroit: ${_formatDate(
                tz.TZDateTime.now(detroitLocation),
              )}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(
              height: 4,
            ),
            Text(
              'Date on Buenos Aires: ${_formatDate(
                tz.TZDateTime.now(argentinaLocation),
              )}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(
              height: 4,
            ),
            Text(
              'Date on Hong Kong: ${_formatDate(
                tz.TZDateTime.now(hongKongLocation),
              )}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) =>
      DateFormat.yMd().add_jm().format(dateTime);
}
