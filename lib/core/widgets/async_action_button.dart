import 'package:flutter/material.dart';

/// Button that morphs into a spinner while [onPressed]'s future is
/// pending — the same "simulate a request" pattern used on the login
/// screen, generalized so any dialog/action (save, delete, confirm...)
/// can reuse it instead of re-implementing its own loading state.
class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style,
    this.loadingLabel,
  });

  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final ButtonStyle? style;

  /// Return a Future to have the button show its loading state until it
  /// completes. Throwing inside is fine — the button just stops loading;
  /// show an error toast from within the callback if needed.
  final Future<void> Function() onPressed;

  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _handleTap,
      style: widget.style,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: _loading
            ? Row(
                key: const ValueKey('loading'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.loadingLabel ?? widget.label),
                ],
              )
            : Row(
                key: const ValueKey('idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[Icon(widget.icon, size: 16), const SizedBox(width: 6)],
                  Text(widget.label),
                ],
              ),
      ),
    );
  }
}
