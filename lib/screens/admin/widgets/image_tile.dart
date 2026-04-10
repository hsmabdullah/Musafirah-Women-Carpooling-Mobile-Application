import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageTile extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isNetwork;

  const ImageTile({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isNetwork = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isNetwork
            ? _buildNetworkOrBase64Image(imagePath)
            : Image.asset(
                imagePath,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _buildError(),
              ),
      ),
    );
  }

  Widget _buildNetworkOrBase64Image(String path) {
    if (path.isEmpty || path == 'null') return _buildError();

    if (path.startsWith('data:image')) {
      try {
        final base64Data = path.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildError(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );
  }
}

