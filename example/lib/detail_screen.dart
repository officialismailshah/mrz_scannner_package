import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as dartImage;

import 'package:mrz_scanner/mrz_scanner.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    Key? key,
    required this.mrzResult,
    required this.id,
    required this.image,
    required this.list,
  }) : super(key: key);
  final MRZResult mrzResult;
  final String id;
  final Uint8List? image;
  final List<String> list;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Uint8List? headedBitmap;
  File? imagePath;

  
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name : ${widget.mrzResult.givenNames}'),
                  Text('Father : ${widget.mrzResult.surnames}'),
                  Text('Gender : ${widget.mrzResult.sex.name}'),
                  Text('Country Issue : ${widget.mrzResult.countryCode}'),
                  Text('Date of Birth : ${widget.mrzResult.birthDate}'),
                  Text('Expiry Date : ${widget.mrzResult.expiryDate}'),
                  Text('DocNum : ${widget.mrzResult.documentNumber}'),
                  Text('Doc Type : ${widget.mrzResult.documentType}'),
                  Text('Phone Number : ${widget.mrzResult.personalNumber}'),
                  Text(
                      'Nationality : ${widget.mrzResult.nationalityCountryCode}'),
                  Text('Id No : ${widget.id}'),
                  widget.image != null
                      ? Image.memory(
                          widget.image!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.amber,
                          width: 150,
                          height: 150,
                        ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.list.map((e) {
                        return Text(e);
                      }).toList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
