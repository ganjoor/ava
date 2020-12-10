import 'package:after_layout/after_layout.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/services/published-recitations-service.dart';
import 'package:ava/view-recitation.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

class RecitationFrame extends StatefulWidget {
  RecitationFrame({
    Key key,
    this.id,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final int id;

  @override
  _RecitationFrameState createState() => _RecitationFrameState(id);
}

class _RecitationFrameState extends State<RecitationFrame>
    with AfterLayoutMixin<RecitationFrame> {
  final GlobalKey<ScaffoldMessengerState> _key =
      GlobalKey<ScaffoldMessengerState>();
  final int id;
  bool _isLoading = false;

  PublicRecitationViewModel _recitation;

  _RecitationFrameState(this.id);

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

  Widget get _mainChild {
    return _recitation == null
        ? Text('در حال بارگذاری')
        : ViewRecitation(
            narration: _recitation,
            loadingStateChanged: this._loadingStateChanged,
            snackbarNeeded: this._snackbarNeeded,
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
                  // Here we take the value from the RecitationFrame object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text('آوای گنجور'),
                  actions: [
                    IconButton(
                        icon: Icon(Icons.refresh),
                        tooltip: 'تازه‌سازی',
                        onPressed: () async {
                          await _loadRecitation();
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
                        child: SingleChildScrollView(child: _mainChild))))));
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    await _loadRecitation();
  }
}
