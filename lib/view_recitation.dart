import 'package:after_layout/after_layout.dart';
import 'package:ava/calbacks/g_ui_callbacks.dart';
import 'package:ava/models/recitation/public_recitation_viewmodel.dart';
import 'package:ava/widgets/audio_player_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ViewRecitation extends StatefulWidget {
  final PublicRecitationViewModel narration;
  final LoadingStateChanged loadingStateChanged;
  final SnackbarNeeded snackbarNeeded;

  const ViewRecitation(
      {Key? key,
      required this.narration,
      required this.loadingStateChanged,
      required this.snackbarNeeded})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ViewRecitationState();
}

class _ViewRecitationState extends State<ViewRecitation>
    with AfterLayoutMixin<ViewRecitation> {
  AudioPlayer? _player;

  final _titleController = TextEditingController();
  final _artistNameController = TextEditingController();
  String _fileDownloadTitle = '';

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
    _player!.dispose();
    _titleController.dispose();
    _artistNameController.dispose();

    super.dispose();
  }

  String getVerse(PublicRecitationViewModel narration, Duration position) {
    if (narration.verses == null) {
      return '';
    }
    var verse = narration.verses!.lastWhere(
        (element) => element.audioStartMilliseconds <= position.inMilliseconds);
    return verse.verseText;
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    _titleController.text = widget.narration.poemFullTitle;
    _artistNameController.text = widget.narration.audioArtist;
    _fileDownloadTitle =
        'دریافت با حجم ${(widget.narration.mp3SizeInBytes / (1024 * 1024)).toStringAsFixed(2)} مگابایت';

    return FocusTraversalGroup(
        child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Wrap(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _titleController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'متن مرتبط',
                        hintText: 'متن مرتبط',
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.open_in_browser),
                          onPressed: () async {
                            var url =
                                'https://ganjoor.net${widget.narration.poemFullUrl}';
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              throw 'خطا در نمایش نشانی $url';
                            }
                          },
                        ))),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _artistNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'به خوانش',
                        hintText: 'به خوانش',
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.open_in_browser),
                          onPressed: () async {
                            var url = widget.narration.audioArtistUrl;
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
                    ControlButtons(_player!, widget.narration,
                        widget.loadingStateChanged, widget.snackbarNeeded),
                    StreamBuilder<Duration?>(
                      stream: _player!.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: _player!.positionStream,
                          builder: (context, snapshot) {
                            var position = snapshot.data ?? Duration.zero;
                            if (position > duration) {
                              position = duration;
                            }
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SeekBar(
                                    duration: duration,
                                    position: position,
                                    onChangeEnd: (newPosition) {
                                      _player!.seek(newPosition);
                                    },
                                  ),
                                  Text(getVerse(widget.narration, position))
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
                        child: Text(_fileDownloadTitle),
                        onPressed: () async {
                          var url = widget.narration.mp3Url;
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            throw 'خطا در نمایش نشانی $url';
                          }
                        },
                      ),
                      ElevatedButton(
                        child: Text(Navigator.canPop(context)
                            ? 'بازگشت'
                            : 'همهٔ خوانش‌ها'),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      )
                    ],
                  )),
            ])));
  }
}
