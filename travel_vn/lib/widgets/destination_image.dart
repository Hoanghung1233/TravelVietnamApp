import 'package:flutter/material.dart';

import '../repositories/destination_repository.dart';

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.repository,
    required this.path,
    this.width,
  });

  final DestinationRepository repository;
  final String path;
  final double? width;

  @override
  Widget build(BuildContext context) => path.isEmpty
      ? const Icon(Icons.image_outlined)
      : Image.network(
          repository.imageUrl(path).toString(),
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined),
        );
}
