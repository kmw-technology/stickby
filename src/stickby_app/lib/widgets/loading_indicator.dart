import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool overlay;

  const LoadingIndicator({
    super.key,
    this.message,
    this.overlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (overlay) {
      return Container(
        color: AppColors.surface.withOpacity(0.9),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: LoadingIndicator(
              message: message,
              overlay: true,
            ),
          ),
      ],
    );
  }
}
