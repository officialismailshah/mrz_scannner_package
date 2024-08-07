import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import 'camera_overlay.dart';

class MRZCameraView extends StatefulWidget {
  const MRZCameraView({
    Key? key,
    required this.onImage,
    this.initialDirection = CameraLensDirection.back,
    required this.showOverlay,
    this.backgroundWidget = const SizedBox(),
    this.backgroundOverlay = const SizedBox(),
    this.loaderBackgroundColor = Colors.red,
    this.loaderActiveColor = Colors.black,
    this.title,
    this.distanceBottom = 100,
    this.distaneTop = 100,
    required this.borderColor,
    this.showLoader = true,
  }) : super(key: key);

  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  final bool showOverlay;
  final Widget backgroundWidget;
  final Widget backgroundOverlay;
  final Widget? title;
  final Color loaderBackgroundColor;
  final bool showLoader;
  final Color loaderActiveColor;
  final double distaneTop;
  final double distanceBottom;
  final Color borderColor;

  @override
  MRZCameraViewState createState() => MRZCameraViewState();
}

class MRZCameraViewState extends State<MRZCameraView> {
  CameraController? _controller;
  int _cameraIndex = 0;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  initCamera() async {
    cameras = await availableCameras();

    try {
      if (cameras.any((element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90)) {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) =>
                element.lensDirection == widget.initialDirection &&
                element.sensorOrientation == 90,
          ),
        );
      } else {
        _cameraIndex = cameras.indexOf(
          cameras.firstWhere(
            (element) => element.lensDirection == widget.initialDirection,
          ),
        );
      }
    } catch (e) {
      print(e);
    }

    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          widget.backgroundWidget,
          widget.backgroundOverlay,
          widget.title == null
              ? const SizedBox()
              : Positioned(
                  top: widget.distaneTop,
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Center(child: widget.title))),
          widget.showLoader
              ? Positioned(
                  bottom: widget.distanceBottom,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        color: widget.loaderBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 5,
                              child: LinearProgressIndicator(
                                color: widget.loaderActiveColor,
                                value: 0.5,
                              )),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
          widget.showOverlay
              ? Center(
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2,
                      child: Center(
                          child: MRZCameraOverlay(child: _liveFeedBody()))),
                )
              : _liveFeedBody(),
        ],
      ),
    );
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false ||
        _controller?.value.isInitialized == null) {
      return Container();
    }
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = (size.aspectRatio * _controller!.value.aspectRatio);
    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return SizedBox(
        height: 250,
        child: Stack(
          children: <Widget>[
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: CustomPaint(
                    foregroundPainter: BorderPainter(color: widget.borderColor),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_controller!),
                        Divider(
                          color: widget.borderColor,
                          thickness: 5,
                        )
                      ],
                    ))),
          ],
        ));
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(camera, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }

      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.length,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

    widget.onImage(inputImage);
  }
}

class BorderPainter extends CustomPainter {
  final Color color;
  BorderPainter({
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    double sh = size.height; // for convenient shortage
    double sw = size.width; // for convenient shortage
    double cornerSide = sh * 0.2; // desirable value for corners side

    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 35
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path path = Path()
      ..moveTo(cornerSide, 0)
      ..quadraticBezierTo(0, 0, 0, cornerSide)
      ..moveTo(0, sh - cornerSide)
      ..quadraticBezierTo(0, sh, cornerSide, sh)
      ..moveTo(sw - cornerSide, sh)
      ..quadraticBezierTo(sw, sh, sw, sh - cornerSide)
      ..moveTo(sw, cornerSide)
      ..quadraticBezierTo(sw, 0, sw - cornerSide, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BorderPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(BorderPainter oldDelegate) => false;
}
