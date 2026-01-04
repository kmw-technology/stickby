import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dismissible card with close button (like legacy ShaddowBoxDecorator)
/// Can be used for welcome messages, tips, or notifications on home screen
class DismissibleCard extends StatefulWidget {
  final String? title;
  final String? message;
  final Widget? child;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool showCloseButton;

  const DismissibleCard({
    super.key,
    this.title,
    this.message,
    this.child,
    this.icon,
    this.iconColor,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.showCloseButton = true,
  });

  @override
  State<DismissibleCard> createState() => _DismissibleCardState();
}

class _DismissibleCardState extends State<DismissibleCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.forward();
    setState(() => _isVisible = false);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart.withOpacity(0.1),
                AppColors.gradientEnd.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: widget.child ??
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.icon != null)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (widget.iconColor ?? AppColors.primary)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.iconColor ?? AppColors.primary,
                              size: 24,
                            ),
                          ),
                        if (widget.icon != null) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null)
                                Text(
                                  widget.title!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              if (widget.title != null && widget.message != null)
                                const SizedBox(height: 4),
                              if (widget.message != null)
                                Text(
                                  widget.message!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              if (widget.actionLabel != null) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: widget.onAction,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.actionLabel!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
              if (widget.showCloseButton)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _handleDismiss,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Welcome card specifically for new users
class WelcomeCard extends StatelessWidget {
  final String userName;
  final VoidCallback? onDismiss;
  final VoidCallback? onGetStarted;

  const WelcomeCard({
    super.key,
    required this.userName,
    this.onDismiss,
    this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return DismissibleCard(
      icon: Icons.waving_hand,
      iconColor: AppColors.warning,
      title: 'Welcome, $userName!',
      message: 'Get started by adding your contact information and creating your first share.',
      actionLabel: 'Add Contact',
      onAction: onGetStarted,
      onDismiss: onDismiss,
    );
  }
}

/// Tip card for showing helpful hints
class TipCard extends StatelessWidget {
  final String tip;
  final VoidCallback? onDismiss;

  const TipCard({
    super.key,
    required this.tip,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return DismissibleCard(
      icon: Icons.lightbulb_outline,
      iconColor: AppColors.info,
      title: 'Tip',
      message: tip,
      onDismiss: onDismiss,
    );
  }
}
