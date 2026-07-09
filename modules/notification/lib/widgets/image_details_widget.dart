import 'package:flutter/material.dart';

import 'package:get/get_utils/get_utils.dart';

class ImageDetailWidget extends StatelessWidget {
  final String imageUrl;

  const ImageDetailWidget({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Image Details".tr,
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.grey,
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

