import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AvailabilityTabWidget extends StatefulWidget {
  const AvailabilityTabWidget({
    Key? key,
    required this.tabs,
    required this.selectedLabel,
    required this.onTabSelected,
  }) : super(key: key);

  final List<String> tabs;
  final String selectedLabel;
  final Function(String) onTabSelected;

  @override
  State<AvailabilityTabWidget> createState() => _AvailabilityTabWidgetState();
}

class _AvailabilityTabWidgetState extends State<AvailabilityTabWidget> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final tabHeight = isMobile ? 40.0 : 50.0;

    // Build a Figma-style rounded pill tab widget with a pale-blue background.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: const Color(0xFFDBEAFE), // pale-blue background per Figma
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children:
            widget.tabs.map((tab) {
              final isSelected = widget.selectedLabel == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTabSelected(tab),
                  child: Container(
                    height:
                        tabHeight - 10, // inner height fits the design (approx)
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          width: 1.26,
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : Colors
                                      .transparent, // invisible stroke as per Figma
                        ),
                      ),
                      shadows:
                          isSelected
                              ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight:
                              isSelected ? FontWeight.w400 : FontWeight.w400,
                          height: 1.43,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// Schedule Availability Card
class ScheduleAvailabilityWidget extends StatefulWidget {
  const ScheduleAvailabilityWidget({super.key});

  @override
  State<ScheduleAvailabilityWidget> createState() =>
      _ScheduleAvailabilityWidgetState();
}

class _ScheduleAvailabilityWidgetState
    extends State<ScheduleAvailabilityWidget> {
  // State for day selections - true means available
  Map<String, bool> _dayAvailability = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
  };

  bool _isLoading = false;
  final APIService _api = APIService(roleOverride: AppRole.staff);
  String _weekStartDate = '';
  String _weekEndDate = '';

  @override
  void initState() {
    super.initState();
    _calculateWeekDates();
    _loadCurrentAvailability();
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    // Find the Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    setState(() {
      _weekStartDate =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      _weekEndDate =
          '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _loadCurrentAvailability() async {
    try {
      final availability = await _api.getMyWeeklyAvailability(
        weekStartDate: _weekStartDate,
      );
      if (availability.isNotEmpty && mounted) {
        setState(() {
          _dayAvailability['Mon'] = availability['monday'] ?? true;
          _dayAvailability['Tue'] = availability['tuesday'] ?? true;
          _dayAvailability['Wed'] = availability['wednesday'] ?? true;
          _dayAvailability['Thu'] = availability['thursday'] ?? true;
          _dayAvailability['Fri'] = availability['friday'] ?? true;
          _dayAvailability['Sat'] = availability['saturday'] ?? false;
        });
      }
    } catch (e) {
      print('[ScheduleAvailability] Error loading availability: $e');
    }
  }

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

  String _getFormattedWeekDates() {
    if (_weekStartDate.isEmpty) return 'Loading...';
    try {
      final monday = DateTime.parse(_weekStartDate);
      final sunday = DateTime.parse(_weekEndDate);
      final monthName = DateFormat('MMM').format(monday);
      return '$monthName ${monday.day} - ${DateFormat('MMM').format(sunday)} ${sunday.day}, ${monday.year}';
    } catch (e) {
      return 'This Week';
    }
  }

  void _submitAvailability() async {
    if (_weekStartDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Week dates not set, please try again')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.submitWeeklyAvailability(
        weekStartDate: _weekStartDate,
        monday: _dayAvailability['Mon'] ?? true,
        tuesday: _dayAvailability['Tue'] ?? true,
        wednesday: _dayAvailability['Wed'] ?? true,
        thursday: _dayAvailability['Thu'] ?? true,
        friday: _dayAvailability['Fri'] ?? true,
        saturday: _dayAvailability['Sat'] ?? false,
        sunday: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth - 32; // Account for padding
    final cardWidth = containerWidth - 32; // Account for internal padding

    // Don't embed its own scroll view — parent (ProfilePage) already provides scrolling.
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main container
          Container(
            width: containerWidth,
            padding: const EdgeInsets.all(8),
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
                                child: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF005CE7),
                                ),
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
                          Text(
                            _getFormattedWeekDates(),
                            style: const TextStyle(
                              color: Color(0xFF626C70),
                              fontSize: 12,
                              fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Days list
                Column(children: _buildDayCards(cardWidth)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Select buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectAllDays,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                          fontFamily: 'Inter',
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
          // Submit button with loading state
          GestureDetector(
            onTap: _isLoading ? null : _submitAvailability,
            child: Container(
              width: containerWidth,
              height: 56,
              decoration: ShapeDecoration(
                color:
                    _isLoading
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF005CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Center(
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
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
    final fullDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

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
              color:
                  isAvailable
                      ? const Color(0xFFE7F7EF)
                      : const Color(0xFFF5F6F7),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.27,
                  color:
                      isAvailable
                          ? const Color(0xFF0FAF62)
                          : const Color(0xFFE5E6E8),
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
                          color:
                              isAvailable
                                  ? const Color(0xFF0FAF62)
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color:
                                  isAvailable
                                      ? Colors.white
                                      : const Color(0xFF959FA3),
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
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 32,
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: ShapeDecoration(
                    color:
                        isAvailable
                            ? const Color(0xFF005CE7) // Active (blue)
                            : const Color(0xFFCBCED4), // Inactive (muted gray)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment:
                        isAvailable
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
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

// Day Off Requests Card
class DayOffRequestsWidget extends StatefulWidget {
  const DayOffRequestsWidget({Key? key}) : super(key: key);

  @override
  State<DayOffRequestsWidget> createState() => _DayOffRequestsWidgetState();
}

class _DayOffRequestsWidgetState extends State<DayOffRequestsWidget> {
  late APIService _api;
  List<Map<String, dynamic>> _dayOffRequests = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _api = APIService(roleOverride: AppRole.staff);
    _loadDayOffRequests();
  }

  Future<void> _loadDayOffRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await _api.getMyDayOffRequests();
      if (mounted) {
        setState(() => _dayOffRequests = requests);
      }
    } catch (e) {
      print('[DayOffRequests] Error loading requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  void _refreshRequests() {
    _loadDayOffRequests();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      height: isMobile ? 100 : 120.93,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFF005CE7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: 0.30,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: isMobile ? 100 : 120.93,
              ),
            ),
          ),
          Positioned(
            left: isMobile ? 16 : 23.99,
            top: isMobile ? 16 : 23.99,
            right: isMobile ? 16 : 0,
            child: Container(
              height: isMobile ? 68 : 72.96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3.98,
                      children: [
                        Text(
                          'Day Off Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                          ),
                        ),
                        Text(
                          'Request time off and track your submissions',
                          style: TextStyle(
                            color: const Color(0xCCFFFEFE),
                            fontSize: isMobile ? 12 : 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (ctx) => DayOffRequestForm(
                                api: _api,
                                onSubmitSuccess: _refreshRequests,
                              ),
                        );

                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Day off request submitted successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _refreshRequests();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 8,
                        ),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: isMobile ? 14 : 16,
                              color: const Color(0xFF005CE7),
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'New Request',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF005CE7),
                                fontSize: isMobile ? 12 : 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
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

// Day Off Request Form (new component for submitting requests)
class DayOffRequestForm extends StatefulWidget {
  final APIService api;
  final VoidCallback onSubmitSuccess;

  const DayOffRequestForm({
    Key? key,
    required this.api,
    required this.onSubmitSuccess,
  }) : super(key: key);

  @override
  State<DayOffRequestForm> createState() => _DayOffRequestFormState();
}

class _DayOffRequestFormState extends State<DayOffRequestForm> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitRequest() async {
    final trimmedReason = _reasonController.text.trim();
    if (_dateController.text.isEmpty || trimmedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.api.submitDayOffRequest(
        requestDate: _dateController.text.trim(),
        reason: trimmedReason,
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
      );
      widget.onSubmitSuccess();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('[DayOffRequestForm] Error submitting day-off request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Request Day Off',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Date',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _dateController.text.isEmpty
                                  ? 'Select a date'
                                  : _dateController.text,
                              style: TextStyle(
                                color:
                                    _dateController.text.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Reason',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Sick leave, Vacation, Personal',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Additional details...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005CE7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Submit Request',
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Real-time Status Update Widget
class RealTimeStatusWidget extends StatefulWidget {
  final VoidCallback onStatusChanged;

  const RealTimeStatusWidget({Key? key, required this.onStatusChanged})
    : super(key: key);

  @override
  State<RealTimeStatusWidget> createState() => _RealTimeStatusWidgetState();
}

class _RealTimeStatusWidgetState extends State<RealTimeStatusWidget> {
  final APIService _api = APIService(roleOverride: AppRole.staff);
  String _currentStatus = 'available';
  bool _isUpdating = false;
  final Map<String, String> _statusLabels = {
    'available': 'Available',
    'busy': 'Busy',
    'on_break': 'On Break',
    'unavailable': 'Unavailable',
    'off_duty': 'Off Duty',
  };

  final Map<String, Color> _statusColors = {
    'available': const Color(0xFF0FAF62),
    'busy': const Color(0xFFFFA500),
    'on_break': const Color(0xFF005CE7),
    'unavailable': const Color(0xFFE84545),
    'off_duty': const Color(0xFF626C70),
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final status = await _api.getRealTimeStatus();
      if (mounted) {
        setState(
          () => _currentStatus = status['current_status'] ?? 'available',
        );
      }
    } catch (e) {
      print('[RealTimeStatus] Error loading status: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _api.updateRealTimeStatus(status: newStatus);
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        widget.onStatusChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_statusLabels[newStatus]}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Status',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _statusLabels.keys.map((status) {
                  final isSelected = _currentStatus == status;
                  return ChoiceChip(
                    label: Text(_statusLabels[status]!),
                    selected: isSelected,
                    onSelected:
                        _isUpdating ? null : (_) => _updateStatus(status),
                    backgroundColor: Colors.white,
                    selectedColor: _statusColors[status],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

// Day Off Card Details
enum DayOffStatus { pending, approved, rejected }

class DayOffRequestCard extends StatelessWidget {
  final String date;
  final String timeAgo;
  final DayOffStatus status;
  final String reason;
  final String? adminNote;

  const DayOffRequestCard({
    Key? key,
    required this.date,
    required this.timeAgo,
    required this.status,
    required this.reason,
    this.adminNote,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status) {
      case DayOffStatus.pending:
        return const Color(0xFFFFFAEB);
      case DayOffStatus.approved:
        return const Color(0xFFE8F7F1);
      case DayOffStatus.rejected:
        return const Color(0xFFFDEDED);
    }
  }

  Color _getStatusTextColor() {
    switch (status) {
      case DayOffStatus.pending:
        return const Color(0xFFF79009);
      case DayOffStatus.approved:
        return const Color(0xFF19B36E);
      case DayOffStatus.rejected:
        return const Color(0xFFE84545);
    }
  }

  String _getStatusText() {
    switch (status) {
      case DayOffStatus.pending:
        return 'Pending';
      case DayOffStatus.approved:
        return 'Approved';
      case DayOffStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1.26, color: Color(0xFFE5E7E8)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(19.98),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 11.99,
              children: [
                // Header with date and status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        spacing: 11.99,
                        children: [
                          // Avatar placeholder
                          Container(
                            width: 47.99,
                            height: 47.99,
                            decoration: ShapeDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment(0.00, 0.00),
                                end: Alignment(1.00, 1.00),
                                colors: [Color(0xFFEEF5FE), Color(0xFFDAEAFE)],
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF0066CC),
                              size: 24,
                            ),
                          ),
                          // Date and time info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 3.98,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: Color(0xFF191B1C),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.50,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: const TextStyle(
                                    color: Color(0xFF959FA3),
                                    fontSize: 12,
                                    fontFamily: 'Inter',
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
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: _getStatusColor(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusTextColor(),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.50,
                        ),
                      ),
                    ),
                  ],
                ),
                // Reason section
                Padding(
                  padding: const EdgeInsets.only(left: 59.99),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3.98,
                    children: [
                      Text(
                        'REASON',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                      Text(
                        reason,
                        style: const TextStyle(
                          color: Color(0xFF191B1C),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ],
                  ),
                ),
                // Admin note for rejected status
                if (status == DayOffStatus.rejected && adminNote != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 59.99),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13.25),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFFDEDED),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.26,
                            color: Color(0xFFE84545),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3.98,
                        children: [
                          const Text(
                            'Rejected by Admin',
                            style: TextStyle(
                              color: Color(0xFFE84545),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                          Text(
                            adminNote!,
                            style: const TextStyle(
                              color: Color(0xFF4A5154),
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
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
    );
  }
}
