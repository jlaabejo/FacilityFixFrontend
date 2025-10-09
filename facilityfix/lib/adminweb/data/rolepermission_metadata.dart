import 'package:flutter/material.dart';

/// Metadata for every permission key in the system.
/// Each entry: key -> { category, label, desc, icon, color }
const Map<String, Map<String, dynamic>> permissionMetadata = {
  'viewUsers': {
    'category': 'Users',
    'label': 'View Users',
    'desc': 'See all users in the system',
    'icon': Icons.group,
    'color': Colors.green,
  },
  'createUsers': {
    'category': 'Users',
    'label': 'Create Users',
    'desc': 'Add new users to the system',
    'icon': Icons.group,
    'color': Colors.green,
  },
  
};
