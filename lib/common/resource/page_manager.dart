import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:upstanders/common/constants/asset_constants.dart';
import 'package:upstanders/common/theme/colors.dart';
import 'package:upstanders/common/widgets/processing_indicator.dart';
import 'package:just_audio/just_audio.dart';

class PageManager {
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final String audioUrl;
  final player = AudioPlayer();

  PageManager(this.audioUrl) {
    _init();
  }

  void _init() async {
    try {
      await player.setUrl(audioUrl);
      var duration = await player.load();
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: duration,
      );
      player.positionStream.listen((position) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: position,
          buffered: oldState.buffered,
          total: oldState.total,
        );
      });
      player.playerStateStream.listen((state) async {
        // print("player.playerStateStream.listen===>$state");
        if (!state.playing) {
          buttonNotifier.value = ButtonState.paused;
        } else if (state.processingState != ProcessingState.completed) {
          buttonNotifier.value = ButtonState.playing;
        } else {
          player.seek(Duration.zero);
          player.pause();
        }
      });
    } on PlayerException catch (e) {
      // iOS/macOS: maps to NSError.code
      // Android: maps to ExoPlayerException.type
      // Web: maps to MediaError.code
      // Linux/Windows: maps to PlayerErrorCode.index
      print("errorororoorro: ${e.code}");
      // iOS/macOS: maps to NSError.localizedDescription
      // Android: maps to ExoPlaybackException.getMessage()
      // Web/Linux: a generic message
      // Windows: MediaPlayerError.message
      print("erroroororororor: ${e.message}");
    } on PlayerInterruptedException catch (e) {
      // This call was interrupted since another audio source was loaded or the
      // player was stopped or disposed before this audio source could complete
      // loading.
      print("erroorororororor: ${e.message}");
    } catch (e) {
      // Fallback for all errors
      print("errorrororororororor====>");
      print(e);
    }
  }

  void play() async {
    await player.play();
  }

  void pause() async {
    await player.pause();
  }

  void seek(Duration position) async {
    player.seek(position);
  }

  void dispose() {
    player.dispose();
  }
}

class ProgressBarState {
  ProgressBarState({
    @required this.current,
    @required this.buffered,
    @required this.total,
  });

  final Duration current;
  final Duration buffered;
  final Duration total;
}

enum ButtonState { paused, playing, loading }

class MusicPlayerr extends StatefulWidget {
  final PageManager pageManager;

  const MusicPlayerr(this.pageManager);

  @override
  _MusicPlayerrState createState() => _MusicPlayerrState();
}

class _MusicPlayerrState extends State<MusicPlayerr> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      color: MyTheme.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [playerWidget(size), popWidget(size)],
      ),
    );
  }

  popWidget(Size size) {
    return Positioned(
      right: 2,
      top: 1.0,
      child: InkWell(
          onTap: () {
            widget.pageManager.pause();
            Navigator.of(context).pop();
          },
          child: Image.asset(
            CIRCULAR_CROSS_ASSET,
            height: size.width * 0.09,
            width: size.width * 0.09,
          )),
    );
  }

  playerWidget(Size size) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      alignment: Alignment.center,
      color: MyTheme.transparent,
      height: size.height * 0.19,
      child: Card(
        elevation: 8,
        child: Container(
            alignment: Alignment.center,
            height: size.height * 0.13,
            width: size.width,
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            decoration: BoxDecoration(
                color: MyTheme.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<ProgressBarState>(
                  valueListenable: widget.pageManager.progressNotifier,
                  builder: (_, value, __) {
                    print("value.total : ${value.total}");
                    return ProgressBar(
                      progress: value.current,
                      buffered: value.buffered,
                      total: value.total,
                      onSeek: widget.pageManager.seek,
                      progressBarColor: MyTheme.primaryColor,
                      baseBarColor: MyTheme.primaryColorWithAlpha80,
                      bufferedBarColor: MyTheme.primaryColorWithAlpha120,
                      thumbColor: MyTheme.primaryColor,
                      barHeight: 5.0,
                      thumbRadius: 7.0,
                    );
                  },
                ),
                ValueListenableBuilder<ButtonState>(
                  valueListenable: widget.pageManager.buttonNotifier,
                  builder: (_, value, __) {
                    switch (value) {
                      case ButtonState.loading:
                        return Container(
                          margin: EdgeInsets.all(8.0),
                          width: 30.0,
                          height: 30.0,
                          child: ProcessingIndicator(
                            size: size.height * 0.0015,
                          ),
                        );
                      case ButtonState.paused:
                        return IconButton(
                          icon: Icon(Icons.play_arrow),
                          iconSize: 30.0,
                          onPressed: widget.pageManager.play,
                        );
                      case ButtonState.playing:
                        return IconButton(
                          icon: Icon(Icons.pause),
                          iconSize: 30.0,
                          onPressed: widget.pageManager.pause,
                        );
                    }
                    return Container(
                      margin: EdgeInsets.all(8.0),
                      width: 30.0,
                      height: 30.0,
                      child: ProcessingIndicator(
                        size: size.height * 0.0015,
                      ),
                    );
                  },
                ),
              ],
            )),
      ),
    );
  }
}
