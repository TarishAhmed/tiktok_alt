import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tiktok_alt/data/video.dart';
import 'package:tiktok_alt/screens/feed_viewmodel.dart';
import 'package:tiktok_alt/widgets/actions_toolbar.dart';
import 'package:tiktok_alt/widgets/video_description.dart';
import 'package:get_it/get_it.dart';
import 'package:stacked/stacked.dart';
import 'package:video_player/video_player.dart';

class FeedScreen extends StatefulWidget {
  FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final pageController = PageController(
    initialPage: 0,
    viewportFraction: 1,
  );
  final locator = GetIt.instance;
  final feedViewModel = GetIt.instance<FeedViewModel>();
  @override
  void initState() {
    super.initState();
    setInitialVideo();
  }

  Timer? _timer;
  static const int REDUCE_TIME = 5;

  int _start = REDUCE_TIME;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
          pageController.nextPage(
              duration: Duration(seconds: 1), curve: Curves.ease);
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  setInitialVideo() async {
    await feedViewModel.loadVideo(0);
    startTimer();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FeedViewModel>.reactive(
      disposeViewModel: false,
      viewModelBuilder: () => feedViewModel,
      builder: (context, model, child) => videoScreen(),
    );
  }

  Widget videoScreen() {
    return Scaffold(
      backgroundColor: GetIt.instance<FeedViewModel>().actualScreen == 0
          ? Colors.black
          : Colors.white,
      body: feedVideos(),
    );
  }

  Widget feedVideos() => Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: feedViewModel.videoSource?.listVideos.length,
            onPageChanged: (index) {
              index = index % (feedViewModel.videoSource!.listVideos.length);
              feedViewModel.changeVideo(index);
              _start = REDUCE_TIME;
              _timer?.cancel();
              startTimer();
            },
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              index = index % (feedViewModel.videoSource!.listVideos.length);
              return videoCard(feedViewModel.videoSource!.listVideos[index]);
            },
          ),
        ],
      );

  Widget videoCard(Video video) {
    return Stack(
      children: [
        video.controller != null
            ? Stack(
                children: [
                  SizedBox.expand(
                      child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: video.controller?.value.size.width ?? 0,
                      height: video.controller?.value.size.height ?? 0,
                      child: VideoPlayer(video.controller!),
                    ),
                  )),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                          child: GestureDetector(
                              onTap: () {
                                if (video.controller!.value.isPlaying) {
                                  video.controller?.pause();
                                  _timer?.cancel();
                                } else {
                                  video.controller?.play();
                                  startTimer();
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                              ))),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black])),
                        child: Container(),
                      ),
                    ],
                  ),
                ],
              )
            : Container(
                color: Colors.black,
                child: Center(
                    child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator())),
              ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                VideoDescription(video.user, video.videoTitle),
                Column(
                  children: [
                    SizedBox(
                        height: 60,
                        width: 60,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                width: double.maxFinite,
                                height: double.maxFinite,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_start',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          shadows: [
                                            Shadow(
                                              offset: Offset(10.0, 10.0),
                                              blurRadius: 3.0,
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                            ),
                                            Shadow(
                                              offset: Offset(10.0, 10.0),
                                              blurRadius: 8.0,
                                              color: Color.fromARGB(
                                                  125, 0, 0, 255),
                                            ),
                                          ],
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                color: Colors.transparent,
                                child: Transform(
                                  transform: Matrix4.rotationY(pi),
                                  child: Transform.translate(
                                    offset: Offset(-48, 12),
                                    child: CircularProgressIndicator(
                                      value: _start / 5,
                                      backgroundColor: Colors.white,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    SizedBox(
                      height: 10,
                    ),
                    ActionsToolbar(video.userPic),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            video.controller != null
                ? Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: VideoProgressIndicator(
                          video.controller!,
                          allowScrubbing: true,
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            SizedBox(height: 20)
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    feedViewModel.controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
