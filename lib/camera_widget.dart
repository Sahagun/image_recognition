

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list, int h, int w);

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final setValues;



  bool isLive = true;
  bool isTakingPicture = false;

  bool isOk(){
    return isLive && !isTakingPicture;
  }

  void buttonPress(){
    isLive = !isLive;
  }


  // The cameraFeed Class takes the cameras list and the setRecognitions
  // function as argument
  CameraFeed(this.cameras, this.isLive, this.setRecognitions, this.setValues);

  @override
  _CameraFeedState createState() => new _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController controller;
  bool isDetecting = false;

  Future<String> testString() async{
    // widget.isTakingPicture = true;
    await new Future.delayed(const Duration(seconds : 5));
    // widget.isTakingPicture = false;
    return Future.value('test future string');
  }

  Future<XFile> takePicture() async{
    if (!controller.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }
    debugPrint('isTakingPicture is ${controller.value.isTakingPicture.toString()}');


    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      print('A capture is already pending, do nothing');
      return null;
    }

    try {
      XFile file = await controller.takePicture();
      return file;
    } on CameraException catch (e) {
      debugPrint(e.toString());
      return null;
    }

    // print('pic delay');
    // widget.isTakingPicture = true;
    // XFile f = await controller.takePicture();
    // await new Future.delayed(const Duration(seconds : 5));
    // widget.isTakingPicture = false;
    // return Future.value(f);

    // if(controller.value.isStreamingImages){
    //   controller.stopImageStream();
    // }
    // return controller.takePicture();
  }

  CameraImage still;



  void startStream(){
    if (controller.value.isStreamingImages){return;}

    controller.startImageStream((CameraImage img) {
      if(!controller.value.isTakingPicture){
        still = img;

        if (!isDetecting) {
          // widget.isTakingPicture = controller.value.isTakingPicture;
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
            widget.setRecognitions(recognitions, img.height, img.width);

            widget.setValues(controller.value, controller);

            isDetecting = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();


    // print(widget.cameras);
    if (widget.cameras == null || widget.cameras.length < 1) {
      // print('No Cameras Found.');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }

        widget.setValues(controller.value, controller);

        setState(() {});

        // if(widget.isLive){
          startStream();
        // }
        // else{
        //   controller.stopImageStream();
        // }

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

    // widget.isTakingPicture = controller.value.isTakingPicture;

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



    if(controller.value.isStreamingImages) {
      // if(widget.isLive && !controller.value.isTakingPicture) {
      startStream();
      return OverflowBox(
        maxHeight:
        screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
        maxWidth:
        screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
        child: CameraPreview(controller),
      );
    }
    else{
        if(controller.value.isStreamingImages){
          controller.stopImageStream();
        }
        return OverflowBox(
            maxHeight:
            screenRatio > previewRatio ? screenH : screenW / previewW *
                previewH,
            maxWidth:
            screenRatio > previewRatio
                ? screenH / previewH * previewW
                : screenW,
            child:
            FutureBuilder(
                future: takePicture(),
                builder: (ctx, snapshot) {
                  // widget.isTakingPicture = true;
                  print('debuggging' + controller.value.isTakingPicture.toString());

                  widget.isTakingPicture = controller.value.isTakingPicture;

                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      print('error: ' + snapshot.error.toString());
                      return Center(
                        child: Text(
                          '${snapshot.error} occured',
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      // widget.isTakingPicture = false;
                      final image = snapshot.data as XFile;
                      return Image.file(File(image.path));
                      // return Text(snapshot.data as String);
                    }
                  }

                  return Center(
                    child: CircularProgressIndicator(),
                    // child: Text(ctx.toString()),


                  // child: Column(
                  //     children: <Widget>[
                  //       Text(TimeOfDay.now().toString()),
                  //       CircularProgressIndicator(),
                  //     ],
                  //   )



                  );
                }
            )
        );

      // return OverflowBox(
      //   maxHeight:
      //   screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      //   maxWidth:
      //   screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      //   child:
      //   FutureBuilder(
      //       future: controller.takePicture(),
      //       builder: (ctx, snapshot){
      //         if (snapshot.connectionState == ConnectionState.done) {
      //           // If we got an error
      //           if (snapshot.hasError) {
      //             return Center(
      //               child: Text(
      //                 '${snapshot.error} occured',
      //                 style: TextStyle(fontSize: 18),
      //               ),
      //             );
      //
      //             // if we got our data
      //           } else if (snapshot.hasData) {
      //             // Extracting data from snapshot object
      //             final image = snapshot.data as XFile;
      //             return  Image.file(File( image.path ) ,
      //             );
      //           }
      //         }
      //
      //         return Center(
      //           child: CircularProgressIndicator(),
      //         );
      //       }
      //   )
      // );
    }
  }
}
