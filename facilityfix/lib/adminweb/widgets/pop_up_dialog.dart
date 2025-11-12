import 'package:flutter/material.dart';

// 🚀 Reusable Dialog Message
// -----------------------------------------------------------------------------

/// Reusable Dialog Configuration
class DialogConfig {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String description;
  final String primaryButtonLabel;
  final VoidCallback primaryAction;
  final String secondaryButtonLabel;
  final VoidCallback secondaryAction;
  final bool isDestructive; // Use for warning/delete actions

  const DialogConfig({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryButtonLabel,
    required this.primaryAction,
    required this.secondaryButtonLabel,
    required this.secondaryAction,
    this.isDestructive = false,
    // Default colors are set for a standard confirmation, overridden below for destructive
    this.iconBg = const Color(0xFFDBEAFE), // Blue background
    this.iconFg = const Color(0xFF2563EB), // Blue foreground
  });

  // Factory constructor for a standard confirmation (e.g., success, info)
  factory DialogConfig.confirmation({
    required String title,
    required String description,
    IconData icon = Icons.info_outline_rounded,
    required String primaryButtonLabel,
    required VoidCallback primaryAction,
    String secondaryButtonLabel = 'Cancel',
    VoidCallback? secondaryAction,
  }) {
    return DialogConfig(
      icon: icon,
      title: title,
      description: description,
      primaryButtonLabel: primaryButtonLabel,
      primaryAction: primaryAction,
      secondaryButtonLabel: secondaryButtonLabel,
      secondaryAction: secondaryAction ?? () {},
      iconBg: const Color(0xFFDBEAFE),
      iconFg: const Color(0xFF2563EB),
      isDestructive: false,
    );
  }

  // Factory constructor for a destructive action (like delete)
  factory DialogConfig.destructive({
    required String title,
    required String description,
    IconData icon = Icons.delete_outline_rounded,
    required String primaryButtonLabel,
    required VoidCallback primaryAction,
    String secondaryButtonLabel = 'Cancel',
    VoidCallback? secondaryAction,
  }) {
    return DialogConfig(
      icon: icon,
      title: title,
      description: description,
      primaryButtonLabel: primaryButtonLabel,
      primaryAction: primaryAction,
      secondaryButtonLabel: secondaryButtonLabel,
      secondaryAction: secondaryAction ?? () {},
      iconBg: const Color(0xFFFEE2E2), // Red background
      iconFg: const Color(0xFFEF4444), // Red foreground
      isDestructive: true,
    );
  }
}

/// 💡 Generic Dialog Message Shower
/// Replaces showDeleteDialog, now takes a DialogConfig object.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required DialogConfig config,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => AppDialog(config: config),
  );
  return result;
}

/// ⚙️ App Dialog Widget (Refactored from DeleteDialog)
class AppDialog extends StatefulWidget {
  final DialogConfig config;

  const AppDialog({super.key, required this.config});

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to close the dialog with an optional result
  Future<void> _close<T>(T? result) async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: DialogContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                // Reusable Icon
                _DialogIcon(
                  icon: widget.config.icon,
                  bg: widget.config.iconBg,
                  fg: widget.config.iconFg,
                ),
                const SizedBox(height: 24),
                // Reusable Title
                DialogTitle(text: widget.config.title),
                const SizedBox(height: 12),
                // Reusable Description
                DialogDescription(text: widget.config.description),
                const SizedBox(height: 32),
                // Reusable Actions with configurable buttons
                _DialogActions(
                  isDestructive: widget.config.isDestructive,
                  secondaryButtonLabel: widget.config.secondaryButtonLabel,
                  primaryButtonLabel: widget.config.primaryButtonLabel,
                  onSecondary: () {
                    // Execute the secondary action and pop the dialog with null/false
                    widget.config.secondaryAction();
                    _close(false);
                  },
                  onPrimary: () {
                    // Execute the primary action and pop the dialog with true/result
                    widget.config.primaryAction();
                    _close(true);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Helper Widgets (Modified to be generic)
// -----------------------------------------------------------------------------

/// Dialog Container (Unchanged)
class DialogContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Dialog Icon (Refactored from DeleteIcon)
class _DialogIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color bg;
  final Color fg;

  const _DialogIcon({
    required this.icon,
    this.size = 72,
    this.iconSize = 36,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

/// Dialog Title (Unchanged)
class DialogTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const DialogTitle({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.color = const Color(0xFF1F2937),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Inter',
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Dialog Description (Unchanged)
class DialogDescription extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;

  const DialogDescription({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w400,
    this.color = const Color(0xFF6B7280),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: color,
          fontFamily: 'Inter',
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

/// Dialog Actions (Refactored from DialogActions)
class _DialogActions extends StatelessWidget {
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final String secondaryButtonLabel;
  final String primaryButtonLabel;
  final bool isDestructive;
  final EdgeInsets padding;
  final double spacing;

  const _DialogActions({
    required this.onSecondary,
    required this.onPrimary,
    required this.secondaryButtonLabel,
    required this.primaryButtonLabel,
    required this.isDestructive,
    this.padding = const EdgeInsets.symmetric(horizontal: 32),
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the isDestructive flag
    final primaryBg = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF2563EB);
    final primaryFg = Colors.white;
    final secondaryBg = const Color(0xFFF3F4F6);
    final secondaryFg = const Color(0xFF374151);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: DialogButton(
              label: secondaryButtonLabel,
              onPressed: onSecondary,
              bg: secondaryBg,
              fg: secondaryFg,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: DialogButton(
              label: primaryButtonLabel,
              onPressed: onPrimary,
              bg: primaryBg,
              fg: primaryFg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog Button (Unchanged)
class DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color bg;
  final Color fg;
  final double height;
  final double radius;
  final double fontSize;
  final FontWeight fontWeight;

  const DialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.bg,
    required this.fg,
    this.height = 50,
    this.radius = 12,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  State<DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.bg.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: widget.fg,
                fontFamily: 'Inter',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}