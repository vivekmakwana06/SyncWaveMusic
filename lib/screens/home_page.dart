import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:sync_music/screens/music_detail_page.dart';

import '../json/songs_json.dart';
import '../theme/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int activeMenu1 = 0;
  int activeMenu2 = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1b1f),
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1b1f),
        elevation: 0,
        title: const Row(
          children: [
            SizedBox(
              width: 10,
              height: 5,
            ),
            Icon(
              Icons.music_note,
              color: Color.fromARGB(255, 181, 76, 6),
              size: 30,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Discovery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Let\'s listen to something cool today',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      body: getBody(),
    );
  }

  PreferredSizeWidget getAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0c091c),
      elevation: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "Discover",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.explore),
          ],
        ),
      ),
    );
  }

  Widget getBody() {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListView.builder(
          itemCount: 4,
          itemBuilder: (context, index) {
            if (index % 2 == 0) {
              // Song types
              List<String>? songTypes;
              int activeMenu = index == 0 ? activeMenu1 : activeMenu2;
              return FutureBuilder<List<String>>(
                // Fetch song types dynamically from Firestore
                future: getSongTypesFromFirestore(index),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: primary,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}"),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text("No song types available"),
                    );
                  } else {
                    songTypes = snapshot.data;
                    return getSongTypeListView(songTypes!, activeMenu);
                  }
                },
              );
            } else {
              // Songs
              return getSongListView();
            }
          },
        );
      },
    );
  }

  Future<List<String>> getSongTypesFromFirestore(int index) async {
    // Fetch song types from Firestore based on the index
    try {
      DocumentSnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("song_types")
              .doc(index == 0 ? "type1" : "type2")
              .get();
      List<String> songTypes =
          List<String>.from(querySnapshot.data()!['types']);
      return songTypes;
    } catch (error) {
      print("Error fetching song types: $error");
      return [];
    }
  }

  Widget getSongTypeListView(List<String> songTypes, int activeMenu) {
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16), // Add padding here
          child: Row(
            children: List.generate(songTypes.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 25),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (songTypes![index] == activeMenu1) {
                        activeMenu1 = index;
                      } else {
                        activeMenu2 = index;
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTypes[index],
                        style: TextStyle(
                          fontSize: 15,
                          color: activeMenu == index ? primary : grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      activeMenu == index
                          ? Container(
                              width: 10,
                              height: 3,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget getSongListView() {
    return SizedBox(
      height: 300,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection("songs").get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No songs available"),
            );
          } else {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, i) {
                var imageUrl = snapshot.data!.docs[i]['image_url'].toString();

                if (imageUrl != "null") {
                  return Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                alignment: Alignment.bottomCenter,
                                child: MusicDetailPage(
                                  title: snapshot.data!.docs[i]['song_name']
                                      .toString(),
                                  color: const Color(0xFF58546c),
                                  description: snapshot
                                      .data!.docs[i]['artist_name']
                                      .toString(),
                                  img: imageUrl,
                                  songUrl: snapshot.data!.docs[i]['song_url']
                                      .toString(),
                                ),
                                type: PageTransitionType.scale,
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                              color: primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 140, left: 140),
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                color: Color.fromARGB(255, 255, 255, 255),
                                onPressed: () {
                                  // Handle delete functionality here
                                  deleteSong(
                                      context, snapshot.data!.docs[i].id);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const SizedBox(height: 20),
                        Text(
                          snapshot.data!.docs[i]['song_name'],
                          style: const TextStyle(
                            fontSize: 15,
                            color: white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 180,
                          child: Text(
                            snapshot.data!.docs[i]['artist_name'],
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(); // Return an empty container for items with a null image URL
                }
              },
            );
          }
        },
      ),
    );
  }

  void deleteSong(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this song?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog and proceed with deletion
                Navigator.of(context).pop();
                await performDelete(documentId);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> performDelete(String documentId) async {
    // Delete the song with the specified documentId
    try {
      await FirebaseFirestore.instance
          .collection("songs")
          .doc(documentId)
          .delete();
      print("Song deleted successfully!");
      // Trigger a rebuild of the widget tree
      setState(() {});
    } catch (error) {
      print("Error deleting song: $error");
    }
  }
}
