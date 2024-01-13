import 'package:flutter/material.dart';
import 'package:sync_music/screens/favorite.dart';
import 'package:sync_music/screens/home_page.dart';
import 'package:sync_music/screens/sync_music.dart';
import 'package:sync_music/screens/upload_music_page.dart';
// import 'package:youtube_sync_music/screens/sync_music.dart';
// import 'package:youtube_sync_music/screens/upload_music_page.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../theme/colors.dart';

class RootApp extends StatefulWidget {
  const RootApp({Key? key}) : super(key: key);

  @override
  _RootAppState createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  int activeTab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      bottomNavigationBar: getFooter(),
      body: getBody(),
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: activeTab,
      children: [
        const HomePage(),
        const SyncMusic(),
        const Favorite(),
        // const Center(
        //   child: Text(
        //     "Search",
        //     style: TextStyle(
        //         fontSize: 20, color: white, fontWeight: FontWeight.bold),
        //   ),
        // ),
        // const Center(
        //   child: Text(
        //     "Setings",
        //     style: TextStyle(
        //         fontSize: 20, color: white, fontWeight: FontWeight.bold),
        //   ),
        // ),
        Upload()
      ],
    );
  }

  Widget getFooter() {
    return SalomonBottomBar(
      currentIndex: activeTab,
      onTap: (index) {
        print("Tapped on index: $index");
        setState(() {
          activeTab = index;
        });
      },
      items: [
        SalomonBottomBarItem(
          icon: Icon(
            Icons.home,
            color: Colors.white,
          ),
          title: Text(
            "Home",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
        SalomonBottomBarItem(
          icon: Icon(
            Icons.book,
            color: Colors.white,
          ),
          title: Text(
            "Sync Music",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
        SalomonBottomBarItem(
          icon: Icon(
            Icons.favorite,
            color: Colors.white,
          ),
          title: Text(
            "Favorite",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
        SalomonBottomBarItem(
          icon: Icon(
            Icons.upload,
            color: Colors.white,
          ),
          title: Text(
            "Upload",
            style: TextStyle(color: Colors.white),
          ),
          selectedColor: primary,
        ),
      ],
    );
  }
}
