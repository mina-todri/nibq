// lib/shared/widgets/loading_widget.dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  const LoadingWidget({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
