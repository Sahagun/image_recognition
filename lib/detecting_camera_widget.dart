import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

import 'bounding_box_widget.dart';
import 'image_converter.dart';

typedef void Callback(List<dynamic> list, int h, int w);

class CameraDetectingFeed extends StatefulWidget {

  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final setValues;
  final Size screen;

  // bool isLive = true;
  // bool isTakingPicture = false;


  // The cameraFeed Class takes the cameras list and the setRecognitions
  // function as argument
  CameraDetectingFeed(this.cameras, this.screen, this.setRecognitions, this.setValues);

  @override
  _CameraDetectingFeedState createState() => new _CameraDetectingFeedState();
}

class _CameraDetectingFeedState extends State<CameraDetectingFeed> {
  CameraController controller;
  bool isDetecting = false;

  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;


  bool isTakingPicture = false;
  bool isLive = true;

  CameraImage imageStill;

  List<int> png;
  File imageFile;

  String imagePath;

  final shift = (0xFF << 24);



  void onCaptureButtonPressed() async {  //on camera button press
    if(controller.value.isTakingPicture){
      return;
    }

    if(isLive){
      isLive = false;

      controller.stopImageStream();
      // XFile imageFile = await controller.takePicture();
      // imagePath = imageFile.path;
      // print('imagePath: ' + imagePath);

      png = await convertImagetoPng(imageStill);

      setState(() { });
    }
    else
    {
      startStreaming();
      setState(() { });
    }


  }

  void startStreaming(){
    if (controller.value.isStreamingImages){return;}
    if (controller.value.isTakingPicture){return;}

    isLive = true;
    imagePath = null;
    png = null;

    controller.startImageStream((CameraImage img) {

      imageStill = img;

      if (!isDetecting) {
        isDetecting = true;
        Tflite.detectObjectOnFrame(
          bytesList: img.planes.map((plane) {return plane.bytes;}).toList(),
          model: "SSDMobileNet",
          imageHeight: img.height,
          imageWidth: img.width,
          imageMean: 127.5,
          imageStd: 127.5,
          numResultsPerClass: 1,
          threshold: 0.4,
        ).then((recognitions) {
          /*
              When setRecognitions is called here, the parameters are being passed on to the parent widget as callback. i.e. to the LiveFeed class
               */
          // widget.setRecognitions(recognitions, img.height, img.width);
          _recognitions = recognitions;
          _imageHeight = img.height;
          _imageWidth = img.width;

          setState(() { });

          isDetecting = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    print(widget.cameras);
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No Cameras Found.');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        controller.setFlashMode(FlashMode.off);
        setState(() {});

        startStreaming();

      });


    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    
    if(isLive){
      return
        Stack(
          children: <Widget>[
            OverflowBox(
              maxHeight:
              screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
              maxWidth:
              screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
              child: CameraPreview(controller),
            ),

            BoundingBox(
              _recognitions == null ? [] : _recognitions,
              math.max(_imageHeight, _imageWidth),
              math.min(_imageHeight, _imageWidth),
              widget.screen.height,
              widget.screen.width,
            ),

            Center(
              child: Align(
                alignment: FractionalOffset.bottomCenter,
                child:
                ElevatedButton(
                  onPressed: onCaptureButtonPressed,
                  child: isLive?Text('Pause'):Text('Resume')
                )
              )
            ),
          ]
        );
    }
    else{
      return
        Stack(
            children: <Widget>[
              OverflowBox(
                maxHeight:
                  screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
                maxWidth:
                  screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
                child:

                // controller.value.isTakingPicture? CircularProgressIndicator() :Image.file(File(imagePath))
                controller.value.isTakingPicture? CircularProgressIndicator() :
                RotatedBox(quarterTurns: 1, child: Image.memory(png))


                // child: Text('Paused'),
              ),

              BoundingBox(
                _recognitions == null ? [] : _recognitions,
                math.max(_imageHeight, _imageWidth),
                math.min(_imageHeight, _imageWidth),
                widget.screen.height,
                widget.screen.width,
              ),

              Center(
                  child: Align(
                      alignment: FractionalOffset.bottomCenter,
                      child:
                      ElevatedButton(
                          onPressed: onCaptureButtonPressed,
                          child: isLive?Text('Pause'):Text('Resume')
                      )
                  )
              ),
            ]
        );
      
    }
    
    

  }
}
