import 'package:after_layout/after_layout.dart';
import 'package:ava/models/common/paginated-items-response-model.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/services/published-recitations-service.dart';
import 'package:ava/view-recitation.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(AvaApp());
}

class AvaApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AvaAppState();
}

class AvaAppState extends State<AvaApp> {
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
        builder: (BuildContext context, Widget child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: 1.0,
                  ),
                  child: child,
                );
              },
            ),
          );
        });
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
  int _pageNumber = 1;
  int _pageSize = 20;
  String _searchTerm = '';

  PaginatedItemsResponseModel<PublicRecitationViewModel> _recitations =
      PaginatedItemsResponseModel<PublicRecitationViewModel>(items: []);

  Future _loadRecitations() async {
    setState(() {
      _isLoading = true;
    });
    var res = await PublishedRecitationsService()
        .getRecitations(_pageNumber, _pageSize, _searchTerm);
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

  void _loadingStateChanged(bool isLoading) {
    setState(() {
      this._isLoading = isLoading;
    });
  }

  void _snackbarNeeded(String msg) {
    _key.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  Future _view(PublicRecitationViewModel recitation) async {
    return showDialog<PublicRecitationViewModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        ViewRecitation _narrationView = ViewRecitation(
          narration: recitation,
          loadingStateChanged: this._loadingStateChanged,
          snackbarNeeded: this._snackbarNeeded,
        );
        return AlertDialog(
          title: Text(recitation.audioTitle),
          content: SingleChildScrollView(
            child: _narrationView,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return ScaffoldMessenger(
        key: _key,
        child: LoadingOverlay(
            isLoading: _isLoading,
            child: Scaffold(
                appBar: AppBar(
                  // Here we take the value from the MyHomePage object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text(widget.title),
                  actions: [
                    IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: 'تازه‌سازی',
                        onPressed: () async {
                          await _loadRecitations();
                        }),
                  ],
                ),
                drawer: Drawer(
                  // Add a ListView to the drawer. This ensures the user can scroll
                  // through the options in the drawer if there isn't enough vertical
                  // space to fit everything.
                  child: ListView(
                    // Important: Remove any padding from the ListView.
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      ListTile(
                        title: Text('اشتراک پادکست'),
                        leading: Icon(Icons.music_note,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url = 'http://feeds.feedburner.com/ganjoorava';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        title: Text('اشتراک خبرنامه'),
                        leading: Icon(Icons.mail,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url =
                              'https://feedburner.google.com/fb/a/mailverify?uri=ganjoorava&loc=en_US';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        title: Text('نحوهٔ مشارکت'),
                        leading: Icon(Icons.mic,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url = 'http://ava.ganjoor.net/about/';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                body: Builder(
                    builder: (context) => Center(
                        child: ListView.builder(
                            itemCount: _recitations.items.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                leading: IconButton(
                                    icon: Icon(Icons.play_arrow),
                                    onPressed: () async {
                                      await _view(_recitations.items[index]);
                                    }),
                                title:
                                    Text(_recitations.items[index].audioTitle),
                                subtitle: Column(children: [
                                  Text(_recitations.items[index].poemFullTitle),
                                  Text(_recitations.items[index].audioArtist),
                                ]),
                              );
                            }))))));
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    await _loadRecitations();
  }
}
