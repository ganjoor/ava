import 'package:after_layout/after_layout.dart';
import 'package:ava/contribute.dart';
import 'package:ava/models/common/paginated-items-response-model.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/routes.dart';
import 'package:ava/search-term.dart';
import 'package:ava/services/published-recitations-service.dart';
import 'package:ava/view-recitation.dart';
import 'package:ava/widgets/audio-player-widgets.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:universal_html/html.dart' hide Text, Navigator;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const AvaApp());
}

class AvaApp extends StatefulWidget {
  const AvaApp({Key key}) : super(key: key);

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
            primarySwatch: Colors.brown,
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
  int _pageSize = 10;
  String _searchTerm = '';
  final int id;
  PublicRecitationViewModel _recitation;
  AudioPlayer _player;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _artistNameController = TextEditingController();

  PaginatedItemsResponseModel<PublicRecitationViewModel> _recitations =
      PaginatedItemsResponseModel<PublicRecitationViewModel>(items: []);

  _MyHomePageState(this.id);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
  }

  @override
  void dispose() {
    _player.dispose();
    _titleController.dispose();
    _artistNameController.dispose();
    super.dispose();
  }

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
    if (_player.playing) {
      await _player.stop();
    }
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

    if (_recitations.items.length > 0) {
      await _expansionCallback(0, true);
    }
  }

  void _loadingStateChanged(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _snackbarNeeded(String msg) {
    _key.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  String getVerse(PublicRecitationViewModel narration, Duration position) {
    if (position == null || narration == null || narration.verses == null) {
      return '';
    }
    var verse = narration.verses.lastWhere(
        (element) => element.audioStartMilliseconds <= position.inMilliseconds);
    if (verse == null) {
      return '';
    }
    return verse.verseText;
  }

  Future _expansionCallback(int index, bool isExpanded) async {
    if (_player.playing) {
      await _player.stop();
    }
    if (!_recitations.items[index].isExpanded) {
      for (var item in _recitations.items) {
        if (item.isExpanded && item.id != _recitations.items[index].id) {
          setState(() {
            item.isExpanded = false;
          });
        }
      }
    }
    setState(() {
      _recitations.items[index].isExpanded =
          !_recitations.items[index].isExpanded;
    });

    if (_recitations.items[index].isExpanded) {
      _titleController.text = _recitations.items[index].audioTitle;
      _artistNameController.text = _recitations.items[index].audioArtist;
    }
  }

  Future<String> _getSearchParams() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('جستجو بر اساس خوانشگر یا متن شعر'),
          content: SingleChildScrollView(
            child: SearchTerm(term: _searchTerm),
          ),
        );
      },
    );
  }

  Widget get _mainChild {
    return id == null
        ? ListView(children: [
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: ExpansionPanelList(
                    key: GlobalKey<ScaffoldMessengerState>(),
                    expansionCallback: _expansionCallback,
                    children: _recitations.items
                        .map((e) => ExpansionPanel(
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                  leading: Icon(Icons.speaker,
                                      color: Theme.of(context).primaryColor),
                                  title: Text(e.poemFullTitle),
                                  subtitle: Text(e.audioArtist));
                            },
                            isExpanded: e.isExpanded,
                            body: FocusTraversalGroup(
                                child: Form(
                                    child: Wrap(children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                  controller: _titleController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                      labelText: 'عنوان',
                                      hintText: 'عنوان',
                                      prefixIcon: IconButton(
                                        icon: const Icon(Icons.open_in_browser),
                                        onPressed: () async {
                                          var url = 'https://ganjoor.net' +
                                              e.poemFullUrl;
                                          if (await canLaunchUrlString(url)) {
                                            await launchUrlString(url);
                                          } else {
                                            throw 'خطا در نمایش نشانی $url';
                                          }
                                        },
                                      )),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextFormField(
                                    controller: _artistNameController,
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor),
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        labelText: 'به خوانش',
                                        hintText: 'به خوانش',
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.open_in_browser),
                                          onPressed: e.audioArtistUrl.isEmpty
                                              ? null
                                              : () async {
                                                  var url = e.audioArtistUrl;
                                                  if (await canLaunchUrlString(url)) {
                                                    await launchUrlString(url);
                                                  } else {
                                                    throw 'خطا در نمایش نشانی $url';
                                                  }
                                                },
                                        ))),
                              ),
                              SafeArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ControlButtons(_player, e,
                                        _loadingStateChanged, _snackbarNeeded),
                                    StreamBuilder<Duration>(
                                      stream: _player.durationStream,
                                      builder: (context, snapshot) {
                                        final duration =
                                            snapshot.data ?? Duration.zero;
                                        return StreamBuilder<Duration>(
                                          stream: _player.positionStream,
                                          builder: (context, snapshot) {
                                            var position =
                                                snapshot.data ?? Duration.zero;
                                            if (position > duration) {
                                              position = duration;
                                            }
                                            return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SeekBar(
                                                    duration: duration,
                                                    position: position,
                                                    onChangeEnd: (newPosition) {
                                                      _player.seek(newPosition);
                                                    },
                                                  ),
                                                  Text(getVerse(e, position))
                                                ]);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ButtonBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        child: const Text('#'),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MyHomePage(id: e.id)));
                                        },
                                      ),
                                      ElevatedButton(
                                        child: const Text('متن'),
                                        onPressed: () async {
                                          var url = 'https://ganjoor.net' +
                                              e.poemFullUrl;
                                          if (await canLaunchUrlString(url)) {
                                            await launchUrlString(url);
                                          } else {
                                            throw 'خطا در نمایش نشانی $url';
                                          }
                                        },
                                      ),
                                      ElevatedButton(
                                        child: Text('دریافت با حجم ' +
                                            (e.mp3SizeInBytes / (1024 * 1024))
                                                .toStringAsFixed(2) +
                                            ' مگابایت'),
                                        onPressed: () async {
                                          var url = e.mp3Url;
                                          if (await canLaunchUrlString(url)) {
                                            await launchUrlString(url);
                                          } else {
                                            throw 'خطا در نمایش نشانی $url';
                                          }
                                        },
                                      )
                                    ],
                                  )),
                            ])))))
                        .toList()))
          ])
        : _recitation == null
            ? const Text('در حال بارگذاری')
            : ViewRecitation(
                narration: _recitation,
                loadingStateChanged: _loadingStateChanged,
                snackbarNeeded: _snackbarNeeded,
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
                  title: const Text('آوای گنجور'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.mic),
                      tooltip: 'من بخوانم',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Contribute()));
                      },
                    ),
                    IconButton(
                        icon: const Icon(Icons.refresh),
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
                        title: const Text('اشتراک پادکست'),
                        leading: Icon(Icons.music_note,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url = 'http://feeds.feedburner.com/ganjoorava';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        title: const Text('اشتراک خبرنامه'),
                        leading: Icon(Icons.mail,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url =
                              'https://feedburner.google.com/fb/a/mailverify?uri=ganjoorava&loc=en_US';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        title: const Text('نحوهٔ مشارکت'),
                        leading: Icon(Icons.mic,
                            color: Theme.of(context).primaryColor),
                        onTap: () async {
                          var url = 'http://ava.ganjoor.net/about/';
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
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
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(currentPageText),
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      tooltip: 'اولین صفحه',
                      onPressed: () async {
                        _pageNumber = 1;
                        await _loadRecitations();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.navigate_before),
                      tooltip: 'صفحهٔ قبل',
                      onPressed: () async {
                        if (_pageNumber > 1) {
                          _pageNumber--;
                          await _loadRecitations();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.navigate_next),
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
                      icon: const Icon(Icons.last_page),
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
                      icon: const Icon(Icons.search),
                      tooltip: 'جستجو',
                      onPressed: () async {
                        var res = await _getSearchParams();
                        if (res != null) {
                          setState(() {
                            _searchTerm = res;
                          });
                          await _loadRecitations();
                        }
                      },
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
