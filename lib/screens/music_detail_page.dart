import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MusicDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final String img;
  final String songUrl;

  const MusicDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
    required this.img,
    required this.songUrl,
  }) : super(key: key);

  @override
  _MusicDetailPageState createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
  int? result;
  bool isPlaying = true;
  bool syncMusic = false;
  Random random = Random();
  Duration duration = const Duration();
  Duration position = const Duration();
  bool isMusicOwner = false;

  late FirebaseFirestore firestore;
  late StreamSubscription<DocumentSnapshot> subscription;

  @override
  void initState() {
    super.initState();
    result = 100000 + random.nextInt(999999 - 100000);

    // Initialize Firestore
    firestore = FirebaseFirestore.instance;

    // Subscribe to changes in the sync document
    subscription = firestore
        .collection("sync")
        .doc(result.toString())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        // Update the state based on the changes in the sync document
        setState(() {
          position = Duration(milliseconds: event["currentPosition"]);
          isPlaying = event["isPlaying"];
        });
      }
    });

    playMusic(widget.songUrl);
  }

  void playMusic(String url) async {
    audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    audioPlayer.play(url);
    audioPlayer.onDurationChanged.listen((event) {
      setState(() {
        duration = event;
      });
    });

    audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        position = event;
        if (syncMusic) {
          updateSyncDocument();
        }
      });
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == AudioPlayerState.PLAYING) {
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    });
  }

  void updateSyncDocument() {
    final docSync = firestore.collection("sync").doc(result.toString());
    docSync.update({
      'currentPosition': position.inMilliseconds,
      'isPlaying': isPlaying,
    });
  }

  seekMusic(int sec) {
    Duration newPosition = Duration(seconds: sec);
    audioPlayer.seek(newPosition);
    if (syncMusic) {
      updateSyncDocument();
    }
  }

  void handlePlayPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.resume();
    }

    // Update the play/pause state in the sync document
    updateSyncDocument();
  }

  // convert format time
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    subscription.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c091c),
      appBar: getAppBar(),
      body: getBody(),
    );
  }

  getAppBar() {
    return AppBar(
      backgroundColor: black,
      elevation: 0,
      actions: const [
        IconButton(
          icon: Icon(
            Icons.more_vert_sharp,
            color: white,
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget getBody() {
    var random = Random();
    final docSync =
        FirebaseFirestore.instance.collection("sync").doc(result.toString());
    result ??= 100000 + random.nextInt(999999 - 100000);

    // Inside MusicDetailPage
    if (result != null && syncMusic) {
      updateSyncDocument();
    }
    var size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                child: Container(
                  width: size.width - 100,
                  height: size.width - 100,
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: widget.color,
                        blurRadius: 50,
                        spreadRadius: 5,
                        offset: const Offset(-10, 40))
                  ], borderRadius: BorderRadius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                child: Container(
                  width: size.width - 60,
                  height: size.width - 60,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(widget.img), fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(20)),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: SizedBox(
              width: size.width - 80,
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.my_library_add,
                    color: white,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 18,
                            color: white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text(
                          widget.description,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15, color: white.withOpacity(0.5)),
                        ),
                      )
                    ],
                  ),
                  const Icon(
                    Icons.more_vert_sharp,
                    color: white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Slider.adaptive(
            activeColor: primary,
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            min: 0.0,
            onChanged: (value) {
              setState(() {
                seekMusic(value.toInt());
              });
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(position),
                  style: TextStyle(color: white.withOpacity(0.5)),
                ),
                Text(
                  formatTime(duration - position),
                  style: TextStyle(color: white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: white.withOpacity(0.8),
                      size: 25,
                    ),
                    onPressed: null),
                IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: white.withOpacity(0.8),
                      size: 25,
                    ),
                    onPressed: null),
                IconButton(
                    iconSize: 50,
                    icon: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: primary),
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                          color: white,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        await audioPlayer.pause();
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        await audioPlayer.resume();
                        setState(() {
                          isPlaying = true;
                        });
                      }
                    }),
                IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: white.withOpacity(0.8),
                      size: 25,
                    ),
                    onPressed: null),
                IconButton(
                    icon: Icon(
                      Icons.cached,
                      color: white.withOpacity(0.8),
                      size: 25,
                    ),
                    onPressed: null)
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
            onTap: () async {
              syncMusic = true;
              docSync.set({
                'musicName': widget.title,
                'artistName': widget.description,
                'songUrl': widget.songUrl,
                'imgUrl': widget.img
              });
              openDialog();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.sync,
                  color: primary,
                  size: 20,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  "Sync Music",
                  style: TextStyle(color: primary),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future openDialog() => showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Music Sync"),
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
            content: SizedBox(
              height: 50,
              child: Column(
                children: [
                  Text(
                    result.toString(),
                    style: const TextStyle(color: primary, fontSize: 40),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
