import 'package:after_layout/after_layout.dart';
import 'package:ava/models/common/paginated-items-response-model.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/routes.dart';
import 'package:ava/services/published-recitations-service.dart';
import 'package:ava/view-recitation.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(AvaApp());
}

class AvaApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AvaAppState();
}

class AvaAppState extends State<AvaApp> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Remove `loading` div
      final loader = document.getElementsByClassName('loading');
      if (loader.isNotEmpty) {
        loader.first.remove();
      }
    }
  }

  static FluroRouter router;
  AvaAppState() {
    router = FluroRouter();
    Routes.configureRoutes(router);
  }
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
            fontFamily: 'Samim'),
        onGenerateRoute: router.generator,
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
  MyHomePage({Key key, this.id}) : super(key: key);

  final int id;

  @override
  _MyHomePageState createState() => _MyHomePageState(id);
}

class _MyHomePageState extends State<MyHomePage>
    with AfterLayoutMixin<MyHomePage> {
  final GlobalKey<ScaffoldMessengerState> _key =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;
  int _pageNumber = 1;
  int _pageSize = 20;
  String _searchTerm = '';
  final int id;
  PublicRecitationViewModel _recitation;

  PaginatedItemsResponseModel<PublicRecitationViewModel> _recitations =
      PaginatedItemsResponseModel<PublicRecitationViewModel>(items: []);

  _MyHomePageState(this.id);

  Future _loadRecitation() async {
    setState(() {
      _isLoading = true;
    });
    var res = await PublishedRecitationsService().getRecitationById(id);
    if (res.item2.isNotEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت خوانش‌ها: " + res.item2),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _isLoading = false;
      if (res.item2.isEmpty) {
        _recitation = res.item1;
      }
    });
  }

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

  Widget get _mainChild {
    return id == null
        ? ListView.builder(
            itemCount: _recitations.items.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () async {
                      await _view(_recitations.items[index]);
                    }),
                title: Text(_recitations.items[index].audioTitle),
                subtitle: Column(children: [
                  Text(_recitations.items[index].poemFullTitle),
                  Text(_recitations.items[index].audioArtist),
                ]),
              );
            })
        : _recitation == null
            ? Text('در حال بارگذاری')
            : ViewRecitation(
                narration: _recitation,
                loadingStateChanged: this._loadingStateChanged,
                snackbarNeeded: this._snackbarNeeded,
              );
  }

  String get currentPageText {
    if (_recitations != null) {
      if (_recitations.paginationMetadata != null) {
        return 'صفحهٔ ' +
            _recitations.paginationMetadata.currentPage.toString() +
            ' از ' +
            _recitations.paginationMetadata.totalPages.toString() +
            ' (' +
            _recitations.items.length.toString() +
            ' از ' +
            _recitations.paginationMetadata.totalCount.toString() +
            ')';
      }
    }

    return '';
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
                  title: Text('آوای گنجور'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.mic),
                      tooltip: 'نحوهٔ مشارکت',
                      onPressed: () async {
                        var url = 'http://ava.ganjoor.net/about/';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'خطا در نمایش نشانی $url';
                        }
                      },
                    ),
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
                persistentFooterButtons: [
                  Row(children: [
                    Text(currentPageText),
                    IconButton(
                      icon: Icon(Icons.first_page),
                      tooltip: 'اولین صفحه',
                      onPressed: () async {
                        _pageNumber = 1;
                        await _loadRecitations();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.navigate_before),
                      tooltip: 'صفحهٔ قبل',
                      onPressed: () async {
                        if (_pageNumber > 1) {
                          _pageNumber--;
                          await _loadRecitations();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.navigate_next),
                      tooltip: 'صفحهٔ بعد',
                      onPressed: () async {
                        if (_pageNumber <
                            _recitations.paginationMetadata.totalPages) {
                          _pageNumber++;
                          await _loadRecitations();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.last_page),
                      tooltip: 'صفحهٔ آخر',
                      onPressed: () async {
                        if (_pageNumber !=
                            _recitations.paginationMetadata.totalPages) {
                          _pageNumber =
                              _recitations.paginationMetadata.totalPages;
                          await _loadRecitations();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      tooltip: 'جستجو',
                      onPressed: null,
                    )
                  ])
                ],
                body:
                    Builder(builder: (context) => Center(child: _mainChild)))));
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    if (id == null) {
      await _loadRecitations();
    } else {
      await _loadRecitation();
    }
  }
}
