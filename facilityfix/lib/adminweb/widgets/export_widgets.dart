import 'package:flutter/material.dart';

// Container

class ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final List<StatusBadge> badges;
  final Widget? actionButtons;
  final Widget? bottomContent;
  final double width;
  final double? height;

  const ExportCard({
    Key? key,
    required this.title,
    required this.description,
    this.badges = const [],
    this.actionButtons,
    this.bottomContent,
    this.width = 1074.98,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      // allow flexible height (height may be null)
      constraints: height != null ? BoxConstraints(minHeight: height!) : null,
      padding: const EdgeInsets.only(
        top: 28.0,
        left: 24.0,
        right: 24.0,
        bottom: 20.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.0, color: const Color(0xFFE5E6E8)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Title, Description, and Badges
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF191B1C),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Badges
                      if (badges.isNotEmpty)
                        Wrap(spacing: 15.99, runSpacing: 8, children: badges),
                    ],
                  ),
                ),
                // Right side - Action Buttons (optional)
                if (actionButtons != null) actionButtons!,
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bottom Container (optional)
          if (bottomContent != null)
            bottomContent!
          else
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: const Color(0xFFE5E6E8)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color dotColor;

  const StatusBadge({Key? key, required this.text, required this.dotColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: ShapeDecoration(
            color: dotColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(41284500),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF626C70),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.50,
          ),
        ),
      ],
    );
  }
}

// Buttons

class ExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;

  const ExportButton({
    Key? key,
    this.onPressed,
    this.text = 'Export All',
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? 0.55 : 1.0,
        child: Container(
          width: 140.67,
          height: 40.99,
          decoration: ShapeDecoration(
            color: const Color(0xFF005CE7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                icon!
              else
                const Icon(Icons.download, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double width;
  final double height;

  const OutlinedButton({
    Key? key,
    this.onPressed,
    required this.text,
    this.icon,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E6E8),
    this.textColor = const Color(0xFF191B1C),
    this.width = 142.61,
    this.height = 37.95,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? 0.55 : 1.0,
        child: Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1.23, color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SizedBox(width: 20, height: 20, child: Center(child: icon)),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Date Range Filter

// Labeled date range filter container
class LabeledDateContainer extends StatelessWidget {
  final String label;
  final String? dateText;
  final String? placeholder;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color placeholderColor;
  final Color labelColor;
  final double width;
  final double height;
  final double borderRadius;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const LabeledDateContainer({
    Key? key,
    required this.label,
    this.dateText,
    this.placeholder = 'Select Date',
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E6E8),
    this.textColor = const Color(0xFF191B1C),
    this.placeholderColor = const Color(0xFF626C70),
    this.labelColor = const Color(0xFF191B1C),
    this.width = 240,
    this.height = 43.45,
    this.borderRadius = 8,
    this.spacing = 8,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.50,
          ),
        ),
        SizedBox(height: spacing),
        // Date Container
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1.23, color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Prefix icon and text
                Expanded(
                  child: Row(
                    children: [
                      if (prefixIcon != null) ...[
                        prefixIcon!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          dateText ?? placeholder ?? '',
                          style: TextStyle(
                            color:
                                dateText != null ? textColor : placeholderColor,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side - Suffix icon
                if (suffixIcon != null) suffixIcon!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Clear Button

class ClearButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final double fontSize;

  const ClearButton({
    Key? key,
    this.onPressed,
    this.text = 'Clear Dates',
    this.backgroundColor = Colors.transparent,
    this.borderColor = const Color(0xFFE5E6E8),
    this.textColor = const Color(0xFF626C70),
    this.width = 112.39,
    this.height = 43.45,
    this.borderRadius = 8,
    this.fontSize = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.23, color: borderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.50,
          ),
        ),
      ),
    );
  }
}
