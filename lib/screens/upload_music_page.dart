import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class Upload extends StatefulWidget {
  const Upload({Key? key}) : super(key: key);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController songName = TextEditingController();
  TextEditingController artistName = TextEditingController();
  double uploadProgress = 0.0;

  late String imagepath, songPath;
  late Reference reference;
  var imageDownloadUrl, songDownloadUrl;
  PlatformFile? imageResult, songResult; // Initialize with a default value

  void selectImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {
      imageResult = result!.files.first;
      File image = File(imageResult!.path!); // Use null-aware operator here
      imagepath = basename(image.path.toString());
      uploadImageFile(image.readAsBytesSync(), imagepath);
    });
  }

  void uploadImageFile(Uint8List image, String imagepath) async {
    reference = FirebaseStorage.instance.ref().child(imagepath);
    UploadTask uploadTask = reference.putData(image);

    TaskSnapshot taskSnapshot = await uploadTask;

    // Get the download URL
    imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Trigger a rebuild to update the UI with the selected image
    setState(() {});
  }

  uploadSongFile(Uint8List song, String songPath) async {
    reference = FirebaseStorage.instance.ref().child(songPath);
    UploadTask uploadTask = reference.putData(song);
    uploadTask.whenComplete(() async {
      void uploadSongFile(Uint8List song, String songPath) async {
        reference = FirebaseStorage.instance.ref().child(songPath);
        UploadTask uploadTask = reference.putData(song);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
          });
        });

        TaskSnapshot taskSnapshot = await uploadTask;
        // Get the download URL
        songDownloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Reset uploadProgress after completing the upload
        setState(() {
          uploadProgress = 0.0;
        });
      }

      try {
        songDownloadUrl = await reference.getDownloadURL();
      } catch (onError) {
        const Text("Errors");
      }
    });
  }

  void selectSong() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    setState(() {
      songResult = result!.files.first;
      File songFile = File(songResult!.path!);
      songPath = basename(songFile.path.toString());
      uploadSongFile(songFile.readAsBytesSync(), songPath);
    });
  }

  void finalUpload(context) async {
    if (songResult != null) {
      File songFile = File(songResult!.path!);

      var data = {
        "song_name": basename(songFile
            .path), // Use the basename of the file path as the song name
        "artist_name": artistName.text,
        "song_url": songDownloadUrl.toString(),
        "image_url": imageDownloadUrl.toString(),
      };

      // Show a dialog with the upload progress

      try {
        await FirebaseFirestore.instance.collection("songs").doc().set(data);

        // Close the progress dialog
        Navigator.of(context).pop();

        // Reset the information after successful upload
        setState(() {
          songName.text = ""; // Clear the song name after upload
          artistName.text = "";
          imageDownloadUrl = null;
          songDownloadUrl = null;
          songResult = null; // Reset the selected song
        });
      } catch (error) {
        // Handle upload errors
        print("Upload error: $error");

        // Close the progress dialog
        Navigator.of(context).pop();

        // You can show an error message or handle it accordingly
      }
    } else {
      // Show an error message if no song is selected
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Please select a song before uploading."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Icons.dashboard_customize,
              color: Color.fromARGB(255, 236, 146, 3),
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
                  'Custom Music Collection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create your cutom collection',
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
      backgroundColor: Color(0xFF1a1b1f),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 30,
                ),
                Divider(thickness: .1),
                ElevatedButton(
                  onPressed: () => selectImage(),
                  child: const Text(
                    "Select Image",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 236, 146, 3),
                    onPrimary: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageDownloadUrl != null
                          ? Image.network(imageDownloadUrl).image
                          : AssetImage("assets/placeholder_image.jpg"),
                      fit: BoxFit.cover,
                    ),
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(thickness: .1),
                ElevatedButton(
                  onPressed: () => selectSong(),
                  child: const Text(
                    "Select Song",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 236, 146, 3),
                    onPrimary: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  " ${songResult?.name ?? ''}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(thickness: .1),
                const SizedBox(height: 20),
                TextField(
                  controller: artistName,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Enter Artist Name",
                    labelStyle: TextStyle(color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 236, 146, 3), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 236, 146, 3), width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 236, 146, 3), width: 3),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(thickness: .1),
                ElevatedButton(
                  onPressed: () => finalUpload(context),
                  child: const Text("Upload"),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 236, 146, 3),
                    onPrimary: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                uploadProgress > 0
                    ? Column(
                        children: [
                          LinearProgressIndicator(
                            value: uploadProgress,
                            backgroundColor: Colors.grey,
                            color: Color.fromARGB(255, 236, 146, 3),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Upload Progress: ${(uploadProgress * 100).toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
