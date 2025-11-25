import 'package:flutter/material.dart';

class SettingsNotificationItem extends StatelessWidget {
  final String title;
  final String description;
  final Widget? icon;
  final bool isEnabled;
  final ValueChanged<bool>? onToggle;

  const SettingsNotificationItem({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.isEnabled = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 402.23,
      height: 73.23,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.26,
            color: const Color(0xFFE5E7E8),
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              width: 338.24,
              height: 39.98,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 11.99,
                children: [
                  Container(
                    width: 39.98,
                    height: 39.98,
                    decoration: ShapeDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0.00, 0.00),
                        end: Alignment(1.00, 1.00),
                        colors: [const Color(0xFFAC46FF), const Color(0xFF980FFA)],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Color(0x19000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                          spreadRadius: -1,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon ?? Container(
                          width: 16,
                          height: 16,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 115.22,
                    height: 38.96,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 115.22,
                            height: 20.98,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: const Color(0xFF191B1C),
                                    fontSize: 14,
                                    fontFamily: 'Arimo',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 20.98,
                          child: Container(
                            width: 115.22,
                            height: 17.98,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: -0.74,
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: const Color(0xFF626C70),
                                      fontSize: 12,
                                      fontFamily: 'Arimo',
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 354.24,
            top: 26.79,
            child: GestureDetector(
              onTap: onToggle != null ? () => onToggle!(!isEnabled) : null,
              child: Container(
                width: 31.99,
                height: 18.39,
                padding: EdgeInsets.only(left: isEnabled ? 14 : 2),
                decoration: ShapeDecoration(
                  color: isEnabled ? const Color(0xFF030213) : const Color(0xFFE5E7E8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1.26,
                      color: Colors.black.withValues(alpha: 0),
                    ),
                    borderRadius: BorderRadius.circular(42152500),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(42152500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationChannelsHeader extends StatelessWidget {
  final String title;
  final Widget? icon;

  const NotificationChannelsHeader({
    super.key,
    this.title = 'Notification Channels',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 405,
      height: 194,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1.26,
            color: const Color(0xFFE5E7E8),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 3,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 402.23,
            height: 46.23,
            padding: const EdgeInsets.only(
              top: 11.99,
              left: 16,
              right: 16,
              bottom: 1.26,
            ),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.00, 0.50),
                end: Alignment(1.00, 0.50),
                colors: [const Color(0xFFEEF5FE), const Color(0xFFEEF2FF)],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.26,
                  color: const Color(0xFFE5E7E8),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20.98,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 2.49,
                        child: Container(
                          width: 16,
                          height: 16,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: icon ?? Stack(),
                        ),
                      ),
                      Positioned(
                        left: 23.99,
                        top: -2,
                        child: Text(
                          title,
                          style: TextStyle(
                            color: const Color(0xFF191B1C),
                            fontSize: 14,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
