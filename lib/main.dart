import 'package:after_layout/after_layout.dart';
import 'package:ava/models/common/paginated-items-response-model.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/services/published-recitations-service.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'آوای گنجور',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'آوای گنجور'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AfterLayoutMixin<MyHomePage> {
  final GlobalKey<ScaffoldMessengerState> _key =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;
  PaginatedItemsResponseModel<PublicRecitationViewModel> _recitations =
      PaginatedItemsResponseModel<PublicRecitationViewModel>(items: []);

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Directionality(
        textDirection: TextDirection.rtl,
        child: ScaffoldMessenger(
            key: _key,
            child: LoadingOverlay(
                isLoading: _isLoading,
                child: Scaffold(
                    appBar: AppBar(
                      // Here we take the value from the MyHomePage object that was created by
                      // the App.build method, and use it to set our appbar title.
                      title: Text(widget.title),
                    ),
                    body: Builder(
                        builder: (context) => Center(
                            child: ListView.builder(
                                itemCount: _recitations.items.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ListTile(
                                    leading: IconButton(
                                        icon: Icon(Icons.play_arrow),
                                        onPressed: null),
                                    title: Text(
                                        _recitations.items[index].audioTitle),
                                    subtitle: Column(children: [
                                      Text(_recitations
                                          .items[index].poemFullTitle),
                                      Text(_recitations
                                          .items[index].audioArtist),
                                    ]),
                                  );
                                })))))));
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    var res = await PublishedRecitationsService().getRecitations(1, 10, '');
    if (res.error.isNotEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت خوانش‌ها: " + res.error),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _isLoading = false;
      if (res.error.isEmpty) {
        _recitations = res;
      }
    });
  }
}
