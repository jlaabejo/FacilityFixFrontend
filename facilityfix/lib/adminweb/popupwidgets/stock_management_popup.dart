import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class StockManagementPopup extends StatefulWidget {
  final Map<String, dynamic> item;

  const StockManagementPopup({
    super.key,
    required this.item,
  });

  @override
  State<StockManagementPopup> createState() => _StockManagementPopupState();

  static Future<bool?> show(BuildContext context, Map<String, dynamic> item) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StockManagementPopup(item: item);
      },
    );
  }
}

class _StockManagementPopupState extends State<StockManagementPopup>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, dynamic>> _transactions = [];
  int _currentStock = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentStock = widget.item['current_stock'] ?? 0;
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _apiService.setAuthToken(token);
      }

      final itemId = widget.item['id'] ?? widget.item['_doc_id'];
      final response = await _apiService.getInventoryTransactions(itemId);

      if (response['success'] == true) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
          // Sort by created_at descending
          _transactions.sort((a, b) {
            final aTime = a['created_at'];
            final bTime = b['created_at'];
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        });
      }
    } catch (e) {
      print('[Stock Management] Error loading transactions: $e');
    }
  }

  Future<void> _addStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      _apiService.setAuthToken(token);
      final itemId = widget.item['id'] ?? widget.item['_doc_id'];
      final quantity = int.parse(_quantityController.text);
      final reason = _reasonController.text.trim();
      final costPerUnit = _costController.text.isNotEmpty
          ? double.parse(_costController.text)
          : null;

      final response = await _apiService.restockInventoryItem(
        itemId,
        quantity,
        reason: reason.isNotEmpty ? reason : null,
        costPerUnit: costPerUnit,
      );

      if (response['success'] == true) {
        setState(() {
          _currentStock += quantity;
          _successMessage = 'Stock added successfully';
          _isLoading = false;
        });
        _quantityController.clear();
        _reasonController.clear();
        _costController.clear();
        await _loadTransactions();

        // Delay to show success message
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response['detail'] ?? 'Failed to add stock';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeStock() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    if (quantity > _currentStock) {
      setState(() {
        _errorMessage = 'Cannot remove more than current stock ($_currentStock)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      _apiService.setAuthToken(token);
      final itemId = widget.item['id'] ?? widget.item['_doc_id'];
      final reason = _reasonController.text.trim();

      final response = await _apiService.consumeInventoryStock(
        itemId,
        quantity,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (response['success'] == true) {
        setState(() {
          _currentStock -= quantity;
          _successMessage = 'Stock removed successfully';
          _isLoading = false;
        });
        _quantityController.clear();
        _reasonController.clear();
        await _loadTransactions();

        // Delay to show success message
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response['detail'] ?? 'Failed to remove stock';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildAddStockTab() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Stock to Inventory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to Add *',
                hintText: 'Enter quantity',
                prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Quantity is required';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost Per Unit (Optional)',
                hintText: 'Enter cost per unit',
                prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Enter reason for restocking',
                prefixIcon: const Icon(Icons.note, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addStock,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? 'Adding...' : 'Add Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveStockTab() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove Stock from Inventory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current Stock: $_currentStock ${widget.item['unit'] ?? 'units'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to Remove *',
                hintText: 'Enter quantity',
                prefixIcon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Quantity is required';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Enter a valid positive number';
                }
                if (qty > _currentStock) {
                  return 'Cannot exceed current stock ($_currentStock)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Enter reason for consumption',
                prefixIcon: const Icon(Icons.note, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _removeStock,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.remove),
                label: Text(_isLoading ? 'Removing...' : 'Remove Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final dt = DateTime.parse(date);
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 700,
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['item_name'] ?? 'Stock Management',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Current: $_currentStock ${widget.item['unit'] ?? 'units'} | Reorder: ${widget.item['reorder_level'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Messages
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red[50],
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.green[50],
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1976D2),
              tabs: const [
                Tab(text: 'Add Stock', icon: Icon(Icons.add_circle_outline)),
                Tab(text: 'Remove Stock', icon: Icon(Icons.remove_circle_outline)),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAddStockTab(),
                  _buildRemoveStockTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
