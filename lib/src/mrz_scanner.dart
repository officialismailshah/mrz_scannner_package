import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mrz_scanner/mrz_scanner.dart';
import 'package:image/image.dart' as dartImage;
import 'camera_view.dart';
import 'mrz_helper.dart';

class MRZScanner extends StatefulWidget {
  const MRZScanner({
    Key? key,
    Key? controller,
    this.initialDirection = CameraLensDirection.back,
    this.onSuccess,
    this.showOverlay = true,
    required this.backgroundWidget,
    required this.backgroundOverlay,
    required this.title,
    required this.loaderBackgroundColor,
    required this.showLoader,
    required this.loaderActiveColor,
    required this.border,
    this.topDst = 100,
    this.bottomDst = 100,
  }) : super(key: controller);
  final Function(MRZResult mrzResult, List<String> lines, Uint8List? image)?
      onSuccess;
  final CameraLensDirection initialDirection;
  final bool showOverlay;

  final Widget backgroundWidget;
  final Widget backgroundOverlay;
  final Widget title;
  final Color loaderBackgroundColor;
  final bool showLoader;
  final Color loaderActiveColor;
  final double topDst;
  final Color border;
  final double bottomDst;
  @override
  MRZScannerState createState() => MRZScannerState();
}

class MRZScannerState extends State<MRZScanner> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _canProcess = true;
  bool _isBusy = false;
  List result = [];

  void resetScanning() => _isBusy = false;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MRZCameraView(
      showOverlay: widget.showOverlay,
      initialDirection: widget.initialDirection,
      onImage: _processImage,
      showLoader: true,
      backgroundWidget: widget.backgroundWidget,
      loaderActiveColor: widget.loaderActiveColor,
      loaderBackgroundColor: widget.loaderBackgroundColor,
      backgroundOverlay: widget.backgroundOverlay,
      title: widget.title,
      distanceBottom: widget.bottomDst,
      distaneTop: widget.topDst,
      borderColor: widget.border,
    );
  }

  void _parseScannedText(
      List<String> lines, InputImage image, CameraController? c) {
    try {
      final data = MRZParser.parse(lines);
      _isBusy = true;
      dartImage.Image img = MRZHelper.decodeYUV420SP(image);
      widget.onSuccess!(data, lines, dartImage.encodeJpg(img));
      c!.stopImageStream();
      c = null;
      c?.dispose();
    } catch (e) {
      _isBusy = false;
    }
  }

  Future<void> _processImage(
      InputImage inputImage, CameraController controller) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final recognizedText = await _textRecognizer.processImage(inputImage);
    String fullText = recognizedText.text;
    String trimmedText = fullText.replaceAll(' ', '');
    List allText = trimmedText.split('\n');

    List<String> ableToScanText = [];
    for (var e in allText) {
      if (MRZHelper.testTextLine(e).isNotEmpty) {
        ableToScanText.add(MRZHelper.testTextLine(e));
      }
    }
    List<String>? result = MRZHelper.getFinalListToParse([...ableToScanText]);

    if (result != null) {
      _parseScannedText([...result], inputImage, controller);
    } else {
      _isBusy = false;
    }
  }
}
