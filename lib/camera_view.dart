import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:object_detection/realtime/bounding_box.dart';
// import 'package:object_detection/realtime/camera.dart';
import 'dart:math' as math;
import 'package:tflite/tflite.dart';

import 'bounding_box_widget.dart';
import 'camera_widget.dart';
import 'detecting_camera_widget.dart';

class LiveFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  LiveFeed(this.cameras);
  @override
  _LiveFeedState createState() => _LiveFeedState();
}

class _LiveFeedState extends State<LiveFeed> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;

  bool _isStreaming = true;
  bool _isTakingPicture = false;
  bool isLive = true;

  CameraValue _cameraValue;
  CameraFeed cameraFeed;

  CameraController _controller;

  initCameras() async {

  }

  loadTfModel() async {
    print('loading files?');
    await Tflite.loadModel(
      model: "assets/models/ssd_mobilenet.tflite",
      labels: "assets/models/labels.txt",
    );
    print('loaded files?');
  }
  /*
  The set recognitions function assigns the values of recognitions, imageHeight and width to the variables defined here as callback
  */
  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  setCameraValue(cameraValue, controller){
    setState(() {
      _cameraValue = cameraValue;
      _controller = controller;
    });
  }

  _nothing(){
    setState(() {
      isLive = !isLive;
      _controller.takePicture();
    });
  }

  @override
  void initState() {
    super.initState();
    loadTfModel();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    cameraFeed = CameraFeed(widget.cameras, isLive, setRecognitions, setCameraValue);



    // print('view debug is taking picutre' +  cameraFeed.isTakingPicture.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text("Real Time Object Detection"),
      ),
      body:

      Container(
        child: CameraDetectingFeed(widget.cameras, screen, setRecognitions, setCameraValue)
      )


      // Stack(
      //   children: <Widget>[
      //     cameraFeed,
      //     BoundingBox(
      //       _recognitions == null ? [] : _recognitions,
      //       math.max(_imageHeight, _imageWidth),
      //       math.min(_imageHeight, _imageWidth),
      //       screen.height,
      //       screen.width,
      //     ),
      //     Center(
      //       child: Align(
      //         alignment: FractionalOffset.bottomCenter,
      //         child:
      //         _cameraValue == null ?
      //         ElevatedButton(
      //             onPressed: null,
      //             child: Text('Pause'))
      //           :
      //             ElevatedButton(
      //                 // onPressed: _cameraValue.isTakingPicture?null:_nothing,
      //                 onPressed: _nothing,
      //                 child: Text(_cameraValue.isStreamingImages?'Pause':'Resume'))
      //       )
      //     )
      //   ],
      // ),





    );
  }
}