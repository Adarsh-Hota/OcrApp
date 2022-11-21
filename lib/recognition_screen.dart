import 'dart:convert';
import 'dart:typed_data';
import 'package:clipboard/clipboard.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_app/secrets.dart';
import 'package:ocr_app/utils.dart';
import 'dart:io' as io;
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  //Storing the image as a File object
  File? pickedImage;
  bool scanning = false;
  String scannedText = '';

  //function for showing dialog box for removing image
  openDialogForRemove(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () => removeImage(),
                child: Text(
                  'Remove image',
                  style: textStyle(20, Colors.black, FontWeight.bold),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: textStyle(20, Colors.black, FontWeight.bold),
                ),
              )
            ],
          );
        });
  }

  //function for showing dialog box for image options
  openDialogForUpload(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () => pickImage(ImageSource.gallery),
                child: Text(
                  'Gallery',
                  style: textStyle(20, Colors.black, FontWeight.bold),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => pickImage(ImageSource.camera),
                child: Text(
                  'Camera',
                  style: textStyle(20, Colors.black, FontWeight.bold),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: textStyle(20, Colors.black, FontWeight.bold),
                ),
              )
            ],
          );
        });
  }

  //function for uploading the images from a device's source
  pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    Navigator.pop(context);
    //Changing the UI i.e. making the chosen image as visible on screen
    setState(() => pickedImage = File(image!.path));
  }

  //function for scanning image
  scanImage(File pickedImage) async {
    //updating UI to depict scanning is happening
    setState(() => scanning = true);
    //preparing the image i.e. converting it to base64 as that is what the api accepts
    Uint8List bytes = io.File(pickedImage.path).readAsBytesSync();
    String img64 = base64Encode(bytes);
    //sending img64 to api as post request
    Uri apiEndpoint = Uri.parse("https://api.ocr.space/parse/image");
    var data = {'base64Image': 'data:image/jpg;base64,$img64'};
    var header = {'apiKey': ocrApiKey};
    http.Response response =
        await http.post(apiEndpoint, body: data, headers: header);
    //Get data back
    Map result = jsonDecode(response.body);
    //Checking data back is error or parsed text
    String finalText = '';
    if (result['OCRExitCode'] == 1) {
      finalText = result['ParsedResults'][0]['ParsedText'];
    } else {
      finalText = result['ErrorMessage'];
    }
    //displaying final result in UI
    setState(() {
      scanning = false;
      scannedText = finalText;
    });
  }

  //function for removing image
  removeImage() {
    Navigator.pop(context);
    setState(() {
      pickedImage = null;
      scannedText = '';
      scanning = false;
    });
  }

  //function for displaying the message "copied to clipboard"
  displayCopyMessage() {
    SnackBar snackBar = SnackBar(
      content: Text(
        'Copied to clipboard',
        style: textStyle(18, Colors.white, FontWeight.w700),
      ),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  //function for sharing text
  shareText() async {
    await Share.share(scannedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9F8),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,

        //Buttons
        children: [
          //Copy button
          FloatingActionButton(
            heroTag: null,
            onPressed: () =>
                FlutterClipboard.copy(scannedText).then(displayCopyMessage()),
            child: const Icon(
              Icons.copy,
              size: 28,
            ),
          ),

          //Space
          const SizedBox(
            width: 10,
          ),

          //Share button
          FloatingActionButton(
            backgroundColor: Colors.red,
            heroTag: null,
            onPressed: () async => await shareText(),
            child: const Icon(
              Icons.reply,
              size: 28,
            ),
          ),
        ],
      ),

      //body
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              //Space
              SizedBox(
                height: 55 + MediaQuery.of(context).viewInsets.top,
              ),

              //Heading
              Text(
                'Text Recognition',
                style: textStyle(30, Colors.blue, FontWeight.w800),
              ),
              const SizedBox(height: 30),

              //Image
              InkWell(
                onTap: pickedImage == null
                    ? null
                    : () => openDialogForRemove(context),
                child: Image(
                  width: 256,
                  height: 256,
                  image: pickedImage == null
                      ? const AssetImage('assets/images/file_add.png')
                      : FileImage(pickedImage!) as ImageProvider,
                  fit: BoxFit.fill,
                ),
              ),

              //Space
              const SizedBox(
                height: 20,
              ),

              //Upload image button
              ElevatedButton(
                  onPressed: (() => openDialogForUpload(context)),
                  child: Text('Upload image',
                      style: textStyle(20, Colors.white, FontWeight.w700))),

              // Space
              const SizedBox(
                height: 10,
              ),

              //Scan button
              ElevatedButton(
                  onPressed: pickedImage == null
                      ? null
                      : () => scanImage(pickedImage!),
                  child: Text('Scan image',
                      style: textStyle(20, Colors.white, FontWeight.w700))),

              //Space
              const SizedBox(
                height: 30,
              ),

              //Scanned text
              scanning == true
                  ? Text('Scanning...',
                      style: textStyle(
                          25, Colors.black.withOpacity(0.6), FontWeight.w600))
                  : Text(scannedText,
                      style: textStyle(
                          25, Colors.black.withOpacity(0.6), FontWeight.w600))
            ],
          ),
        ),
      ),
    );
  }
}
