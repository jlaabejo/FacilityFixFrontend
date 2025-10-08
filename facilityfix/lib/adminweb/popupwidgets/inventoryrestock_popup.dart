import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestockDialog extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const RestockDialog({
    super.key,
    required this.itemData,
  });

  @override
  State<RestockDialog> createState() => _RestockDialogState();

  // Static method to show the dialog
  static Future<Map<String, dynamic>?> show(BuildContext context, Map<String, dynamic> data) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return RestockDialog(itemData: data);
      },
    );
  }
}

class _RestockDialogState extends State<RestockDialog> {
  // Controller for quantity input
  final TextEditingController _quantityController = TextEditingController();
  
  // Flag to enable/disable restock button
  bool _isRestockEnabled = false;
  
  // Loading state for restock action
  bool _isRestocking = false;

  @override
  void initState() {
    super.initState();
    // Listen to quantity changes for real-time validation
    _quantityController.addListener(_validateQuantity);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Real-time validation for quantity input
  void _validateQuantity() {
    final text = _quantityController.text.trim();
    setState(() {
      // Enable button only if input is not empty and is a valid positive number
      if (text.isEmpty) {
        _isRestockEnabled = false;
      } else {
        final quantity = int.tryParse(text);
        _isRestockEnabled = quantity != null && quantity > 0;
      }
    });
  }

  // Handle restock action (backend ready)
  Future<void> _handleRestock() async {
    if (!_isRestockEnabled) return;

    setState(() {
      _isRestocking = true;
    });

    try {
      final quantity = int.parse(_quantityController.text.trim());
      
      // TODO: Replace with actual API call
      // Example:
      // await RestockService.restockItem(
      //   itemId: widget.itemData['id'],
      //   quantity: quantity,
      // );
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully restocked ${widget.itemData['name']} with $quantity units',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Close dialog and return the restocked data
      Navigator.of(context).pop({
        'success': true,
        'itemId': widget.itemData['id'],
        'quantity': quantity,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Handle error
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restock: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestocking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 400,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // Content section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: _buildContent(),
              ),
            ),
            
            // Footer with action buttons
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Main content section
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row with Item name + Close button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.itemData['name'] ?? 'Item Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.grey,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Item ID
        Text(
          widget.itemData['id'] ?? 'INV-2025-XXX',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),

        const SizedBox(height: 32),

        // Quantity input section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Quantity input field with unit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., 50',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    widget.itemData['unit'] ?? 'pcs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            // Validation hint
            if (_quantityController.text.isNotEmpty && !_isRestockEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Please enter a valid quantity greater than 0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Footer with action buttons
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isRestocking ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Restock button
          Expanded(
            child: ElevatedButton(
              onPressed: _isRestockEnabled && !_isRestocking
                  ? _handleRestock
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 39, 134, 224),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isRestocking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Restock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}