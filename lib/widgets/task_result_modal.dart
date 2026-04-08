import 'package:flutter/material.dart';

class TaskResultModal extends StatefulWidget {
  const TaskResultModal({
    super.key,
    required this.isSuccess,
    required this.message,
    this.duration = const Duration(milliseconds: 3000),
  });

  final bool isSuccess;
  final String message;
  final Duration duration;

  @override
  State<TaskResultModal> createState() => _TaskResultModalState();
}

class _TaskResultModalState extends State<TaskResultModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto-close after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = widget.isSuccess;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isSuccess
                    ? colorScheme.primaryContainer
                    : colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? colorScheme.primary : colorScheme.error)
                        .withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon with pulse effect
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
                      ),
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? colorScheme.primary
                            : colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isSuccess ? Icons.check_rounded : Icons.close_rounded,
                          size: 48,
                          color: isSuccess
                              ? colorScheme.onPrimary
                              : colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Message
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSuccess
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
