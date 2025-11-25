import 'package:flutter/material.dart';

class ScheduleAvailabilityWidget extends StatefulWidget {
  const ScheduleAvailabilityWidget({super.key});

  @override
  State<ScheduleAvailabilityWidget> createState() => _ScheduleAvailabilityWidgetState();
}

class _ScheduleAvailabilityWidgetState extends State<ScheduleAvailabilityWidget> {
  // State for day selections - true means available
  Map<String, bool> _dayAvailability = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
  };

  void _toggleDay(String day) {
    setState(() {
      _dayAvailability[day] = !_dayAvailability[day]!;
    });
  }

  void _selectAllDays() {
    setState(() {
      _dayAvailability.updateAll((key, value) => true);
    });
  }

  void _selectWeekdaysOnly() {
    setState(() {
      _dayAvailability['Mon'] = true;
      _dayAvailability['Tue'] = true;
      _dayAvailability['Wed'] = true;
      _dayAvailability['Thu'] = true;
      _dayAvailability['Fri'] = true;
      _dayAvailability['Sat'] = false;
    });
  }

  void _submitAvailability() {
    // TODO: Implement submit logic
    print('Submitting availability: $_dayAvailability');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 32; // Account for padding
    final cardWidth = containerWidth - 32; // Account for internal padding

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main container
          Container(
            width: containerWidth,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.27,
                  color: const Color(0xFFE5E6E8),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'This Week',
                                style: TextStyle(
                                  color: Color(0xFF191B1C),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nov 18 - Nov 24, 2024',
                            style: TextStyle(
                              color: Color(0xFF626C70),
                              fontSize: 12,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_dayAvailability.values.where((v) => v).length}/7',
                          style: const TextStyle(
                            color: Color(0xFF005CE7),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.50,
                          ),
                        ),
                        const Text(
                          'Days',
                          style: TextStyle(
                            color: Color(0xFF626C70),
                            fontSize: 10,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Days list
                Column(
                  children: _buildDayCards(cardWidth),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Select buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectAllDays,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.27,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Select All Days',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _selectWeekdaysOnly,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.27,
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Weekdays Only',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontFamily: 'Arimo',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Submit button
          GestureDetector(
            onTap: _submitAvailability,
            child: Container(
              width: containerWidth,
              height: 56,
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(0.50, 0.00),
                  end: Alignment(0.50, 1.00),
                  colors: [Color(0xFF005CE8), Color(0xFF0047B3)],
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                shadows: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                    spreadRadius: -3,
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  'Submit Availability',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayCards(double cardWidth) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    return List.generate(days.length, (index) {
      final day = days[index];
      final fullDay = fullDays[index];
      final isAvailable = _dayAvailability[day]!;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _toggleDay(day),
          child: Container(
            width: cardWidth,
            height: 66.52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: isAvailable ? const Color(0xFFE7F7EF) : const Color(0xFFF5F6F7),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.27,
                  color: isAvailable ? const Color(0xFF0FAF62) : const Color(0xFFE5E6E8),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          color: isAvailable ? const Color(0xFF0FAF62) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: isAvailable ? Colors.white : const Color(0xFF959FA3),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullDay,
                              style: const TextStyle(
                                color: Color(0xFF191B1C),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              isAvailable ? 'Available' : 'Unavailable',
                              style: const TextStyle(
                                color: Color(0xFF626C70),
                                fontSize: 12,
                                fontFamily: 'Arimo',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 18,
                  decoration: ShapeDecoration(
                    color: isAvailable ? const Color(0xFF030213) : const Color(0xFFCBCED4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class DayOffRequestsHeader extends StatelessWidget {
  final VoidCallback? onNewRequest;
  final String title;
  final String description;

  const DayOffRequestsHeader({
    super.key,
    this.onNewRequest,
    this.title = 'Day Off Requests',
    this.description = 'Request time off and track your submissions',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364.74,
      height: 72.96,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 0,
        children: [
          Container(
            width: 225.26,
            height: 72.96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3.98,
              children: [
                Container(
                  width: double.infinity,
                  height: 29.99,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: -2.74,
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Arimo',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 38.98,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: -2,
                        child: SizedBox(
                          width: 181,
                          child: Text(
                            description,
                            style: TextStyle(
                              color: const Color(0xCCFFFEFE),
                              fontSize: 13,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNewRequest,
            child: Container(
              width: 139.48,
              height: 36,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                shadows: [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                    spreadRadius: -3,
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 11.99,
                    top: 9.99,
                    child: Container(
                      width: 16,
                      height: 16,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(),
                      child: Stack(),
                    ),
                  ),
                  Positioned(
                    left: 43.97,
                    top: 6.01,
                    child: Text(
                      'New Request',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF005CE7),
                        fontSize: 14,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DayOffRequestStatus {
  pending,
  approved,
  rejected,
}

class DayOffRequestItem extends StatelessWidget {
  final String date;
  final String timeAgo;
  final String reason;
  final DayOffRequestStatus status;

  const DayOffRequestItem({
    super.key,
    required this.date,
    required this.timeAgo,
    required this.reason,
    required this.status,
  });

  Color _getStatusBackgroundColor() {
    switch (status) {
      case DayOffRequestStatus.pending:
        return const Color(0xFFFEF3C7);
      case DayOffRequestStatus.approved:
        return const Color(0xFFE7F7EF);
      case DayOffRequestStatus.rejected:
        return const Color(0xFFFEE2E2);
    }
  }

  Color _getStatusTextColor() {
    switch (status) {
      case DayOffRequestStatus.pending:
        return const Color(0xFFF59E0B);
      case DayOffRequestStatus.approved:
        return const Color(0xFF0FAF62);
      case DayOffRequestStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText() {
    switch (status) {
      case DayOffRequestStatus.pending:
        return 'Pending';
      case DayOffRequestStatus.approved:
        return 'Approved';
      case DayOffRequestStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 410.20,
      height: 150.89,
      child: Stack(
        children: [
          Positioned(
            left: 19.98,
            top: 19.98,
            child: Container(
              width: 370.24,
              height: 47.99,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 32.41,
                children: [
                  Container(
                    width: 257.31,
                    height: 47.99,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 11.99,
                      children: [
                        Container(
                          width: 47.99,
                          height: 47.99,
                          padding: const EdgeInsets.only(right: 0.02),
                          decoration: ShapeDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(0.00, 0.00),
                              end: Alignment(1.00, 1.00),
                              colors: [const Color(0xFFEEF5FE), const Color(0xFFDAEAFE)],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 19.98,
                                height: 19.98,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 197.33,
                          height: 44.46,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 3.98,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 22.49,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      date,
                                      style: TextStyle(
                                        color: const Color(0xFF191B1C),
                                        fontSize: 15,
                                        fontFamily: 'Arimo',
                                        fontWeight: FontWeight.w400,
                                        height: 1.50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 17.98,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: -0.74,
                                      child: Text(
                                        timeAgo,
                                        style: TextStyle(
                                          color: const Color(0xFF959FA3),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80.52,
                    height: 19.94,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: _getStatusBackgroundColor(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 7.99,
                          top: 3.97,
                          child: Container(
                            width: 11.99,
                            height: 11.99,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(),
                            child: Stack(),
                          ),
                        ),
                        Positioned(
                          left: 27.95,
                          top: 0.98,
                          child: Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: _getStatusTextColor(),
                              fontSize: 12,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w400,
                              height: 1.33,
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
            left: 79.97,
            top: 79.97,
            child: Container(
              width: 310.25,
              height: 42.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3.98,
                children: [
                  Container(
                    width: double.infinity,
                    height: 17.98,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: -0.74,
                          child: Text(
                            'REASON',
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
                  Container(
                    width: double.infinity,
                    height: 20.98,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 310.25,
                          child: Text(
                            reason,
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
          ),
        ],
      ),
    );
  }
}

class CurrentWeekStatusWidget extends StatelessWidget {
  final String title;
  final String status;
  final String availability;
  final String submittedTime;

  const CurrentWeekStatusWidget({
    super.key,
    this.title = 'Current Week Status',
    this.status = 'Active & Approved',
    this.availability = '5/7 Days',
    this.submittedTime = '3 days ago',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 372.80,
      height: 130.90,
      child: Stack(
        children: [
          // Main content
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 372.80,
              height: 130.90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Container(
                    width: double.infinity,
                    height: 45.60,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 12,
                      children: [
                        Container(
                          width: 45.60,
                          height: 45.60,
                          padding: const EdgeInsets.only(
                            top: 10.80,
                            left: 10.80,
                            right: 10.80,
                            bottom: 0.80,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 0.80,
                                color: const Color(0x4CFFFEFE),
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 6,
                                offset: Offset(0, 4),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 15,
                                offset: Offset(0, 10),
                                spreadRadius: -3,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 24,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 147.09,
                          height: 45,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.90,
                                child: Container(
                                  width: double.infinity,
                                  height: 18,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 147.09,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                            height: 1.50,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 27,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 1.20,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
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
                  ),
                  Container(
                    width: double.infinity,
                    height: 69.30,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.80,
                          color: const Color(0x4CFFFEFE),
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 16.80,
                          child: Container(
                            width: 178.40,
                            height: 52.50,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Opacity(
                                  opacity: 0.90,
                                  child: Container(
                                    width: double.infinity,
                                    height: 16.50,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: -1.20,
                                          child: Text(
                                            'AVAILABILITY',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontFamily: 'Arimo',
                                              fontWeight: FontWeight.w400,
                                              height: 1.50,
                                              letterSpacing: 0.28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 30,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0.20,
                                        child: Text(
                                          availability,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
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
                        ),
                        Positioned(
                          left: 194.40,
                          top: 16.80,
                          child: Container(
                            width: 178.40,
                            height: 52.50,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Opacity(
                                  opacity: 0.90,
                                  child: Container(
                                    width: double.infinity,
                                    height: 16.50,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: -1.20,
                                          child: Text(
                                            'SUBMITTED',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontFamily: 'Arimo',
                                              fontWeight: FontWeight.w400,
                                              height: 1.50,
                                              letterSpacing: 0.28,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 30,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0.20,
                                        child: Text(
                                          submittedTime,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Background overlay
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: 0.20,
              child: Container(
                width: 412.80,
                height: 170.90,
                padding: const EdgeInsets.only(top: -64, left: 348.80, right: -64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 128,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26843500),
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

enum ScheduleSubmissionStatus {
  pending,
  approved,
  rejected,
}

class ScheduleSubmissionHistoryItem extends StatelessWidget {
  final String dateRange;
  final String submissionTime;
  final String availability;
  final ScheduleSubmissionStatus status;

  const ScheduleSubmissionHistoryItem({
    super.key,
    required this.dateRange,
    required this.submissionTime,
    required this.availability,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case ScheduleSubmissionStatus.pending:
        return const Color(0xFFF59E0B);
      case ScheduleSubmissionStatus.approved:
        return const Color(0xFF0FAF62);
      case ScheduleSubmissionStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText() {
    switch (status) {
      case ScheduleSubmissionStatus.pending:
        return 'Pending';
      case ScheduleSubmissionStatus.approved:
        return 'Approved';
      case ScheduleSubmissionStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 416,
      height: 165.40,
      padding: const EdgeInsets.only(top: 16, left: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.80,
            color: const Color(0xFFE5E6E8),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 36,
        children: [
          Container(
            width: 382.40,
            height: 43,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: 43,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 21,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Container(
                                width: 149.24,
                                height: 21,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: -0.40,
                                      child: Text(
                                        dateRange,
                                        style: TextStyle(
                                          color: const Color(0xFF191B1C),
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          height: 1.50,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 50.58,
                                height: 20.60,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 0.80,
                                      color: const Color(0xFF005CE7),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      'Weekly',
                                      style: TextStyle(
                                        color: const Color(0xFF005CE7),
                                        fontSize: 10,
                                        fontFamily: 'Arimo',
                                        fontWeight: FontWeight.w400,
                                        height: 1.50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 18,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(),
                                child: Stack(),
                              ),
                              Container(
                                width: 129.29,
                                height: 18,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: -1.20,
                                      child: Text(
                                        submissionTime,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ],
            ),
          ),
          Container(
            width: 382.40,
            height: 52.80,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.80,
                  color: const Color(0xFFE5E6E8),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 249.35,
              children: [
                Container(
                  width: 58.24,
                  height: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 15,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: -1.20,
                              child: Text(
                                'Availability',
                                style: TextStyle(
                                  color: const Color(0xFF626C70),
                                  fontSize: 10,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 21,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0.20,
                              top: -0.05,
                              child: SizedBox(
                                width: 117,
                                child: Text(
                                  availability,
                                  style: TextStyle(
                                    color: const Color(0xFF191B1C),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.50,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 74.81,
                  height: 18,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(),
                        child: Stack(),
                      ),
                      Expanded(
                        child: Container(
                          height: 18,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: -0.20,
                                child: Text(
                                  _getStatusText(),
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }
}