# Round-Robin Task Assignment System

## Overview

The Round-Robin Assignment System provides **automatic, fair distribution of tasks** to staff members within each department. It uses a pointer/index mechanism per department to cycle through available staff, ensuring balanced workload distribution.

## Features

✅ **Fair Distribution**: Automatically rotates assignments among available staff  
✅ **Department-Based**: Maintains separate rotation for each department  
✅ **Persistent State**: Remembers assignment position even after app restart  
✅ **Manual Override**: Admins can still manually assign if needed  
✅ **Availability Checking**: Only assigns to available staff members  
✅ **Statistics Tracking**: Monitor assignment distribution per department  

## Architecture

### Components

1. **`RoundRobinAssignmentService`** (`lib/adminweb/services/round_robin_assignment_service.dart`)
   - Core service handling round-robin logic
   - Maintains department pointers
   - Integrates with API for staff retrieval and assignment

2. **`AssignScheduleWorkDialog`** (`lib/adminweb/popupwidgets/assignstaff_popup.dart`)
   - UI component with Auto-Assign button
   - Manual and automatic assignment options
   - Task type detection (concern slip, job service, maintenance, work order)

3. **`ApiService`** (`lib/adminweb/services/api_service.dart`)
   - Enhanced with `assignStaffToWorkOrder()` method
   - Handles all assignment API calls

## How It Works

### Round-Robin Algorithm

```
1. Fetch all available staff for department
2. Get current pointer index for department (stored in SharedPreferences)
3. Calculate next index: pointer % staff_count
4. Assign task to staff at calculated index
5. Increment pointer and save for next assignment
```

### Department Pointers

Each department maintains its own pointer:

```dart
{
  "electrical": 2,    // Next assignment goes to 3rd staff member
  "plumbing": 0,      // Next assignment goes to 1st staff member
  "maintenance": 5,   // Next assignment goes to 6th staff member
  ...
}
```

### Persistence

Pointers are stored in `SharedPreferences` with keys:
- `rr_pointer_electrical`
- `rr_pointer_plumbing`
- `rr_pointer_maintenance`
- etc.

## Usage

### Auto-Assign Button (Admin Web)

1. Click "Assign Staff" on any task
2. Click the **"Auto-Assign"** button (orange button with refresh icon)
3. System automatically:
   - Detects task department/category
   - Finds next staff member in rotation
   - Assigns the task
   - Shows confirmation with staff name

### Manual Assignment (Traditional)

1. Click "Assign Staff" on any task
2. Select staff member from dropdown
3. (Optional) Select schedule date
4. (Optional) Add notes
5. Click "Save & Assign Staff"

## API Integration

### Required API Endpoints

The system uses these backend endpoints:

```
GET  /users/staff?department={dept}&available_only=true
PATCH /concern-slips/{id}/assign-staff
PATCH /job-services/{id}/assign
PATCH /work-orders/{id}/assign
```

### Task Types Supported

- **Concern Slips**: Basic repair requests from tenants
- **Job Services**: Scheduled service tasks
- **Work Orders**: Work permit requests
- **Maintenance**: Preventive maintenance tasks

## Configuration

### Department Mapping

The system maps task categories to departments:

```dart
'electrical' → 'electrical'
'plumbing' → 'plumbing'
'hvac' → 'hvac'
'carpentry' → 'carpentry'
'maintenance' → 'maintenance'
'security' → 'security'
'fire_safety' → 'fire_safety'
```

### Availability Filter

Staff members are filtered by:
- Department match
- `available_only: true` flag (checks staff availability status)

## Advanced Features

### Preview Next Assignment

```dart
final rrService = RoundRobinAssignmentService();
final nextStaff = await rrService.previewNextAssignment('electrical');
print('Next assignment will go to: ${nextStaff['first_name']}');
```

### Get Assignment Statistics

```dart
final rrService = RoundRobinAssignmentService();
final stats = await rrService.getAssignmentStatistics();
// Returns: {'electrical': 5, 'plumbing': 3, 'maintenance': 8}
```

### Reset Department Pointer

```dart
final rrService = RoundRobinAssignmentService();
await rrService.resetDepartmentPointer('electrical');
// Next assignment starts from first staff member again
```

### Reset All Pointers

```dart
final rrService = RoundRobinAssignmentService();
await rrService.resetAllPointers();
// All departments reset to first staff member
```

## Error Handling

### No Available Staff

If no staff are available in a department:
```
Error: "No available staff found in {department} department"
```

**Solution**: 
- Check staff availability status
- Assign staff to the department
- Ensure staff are marked as available

### Task ID Not Found

```
Error: "Task ID not found"
```

**Solution**:
- Verify task data structure includes `id` field
- Check `rawData` object for concern slips

### Assignment API Failed

```
Error: "Failed to assign task {id}"
```

**Solution**:
- Check backend API is running
- Verify authentication token
- Check API endpoint exists

## Customization

### Modify Department List

Edit `_handleAutoAssign()` in `assignstaff_popup.dart`:

```dart
switch (taskCategory) {
  case 'your_new_category':
    department = 'your_new_department';
    break;
  // ... existing cases
}
```

### Change Pointer Storage

Replace `SharedPreferences` in `round_robin_assignment_service.dart`:

```dart
// Current: SharedPreferences (local device storage)
// Alternative: Firebase Firestore (cloud sync across devices)
// Alternative: Backend API (centralized server storage)
```

### Custom Assignment Logic

Override `getNextStaffForDepartment()`:

```dart
Future<Map<String, dynamic>?> getNextStaffForDepartment(String department) async {
  // Your custom logic here
  // E.g., skill-based routing, workload balancing, etc.
}
```

## Testing

### Test Auto-Assignment

1. Create multiple staff members in same department
2. Create several tasks in that department
3. Use Auto-Assign repeatedly
4. Verify assignments rotate through all staff members

### Test Pointer Persistence

1. Auto-assign a task
2. Close and reopen the app
3. Auto-assign another task
4. Verify it continues from next staff member (not first)

### Test Department Isolation

1. Auto-assign electrical task
2. Auto-assign plumbing task
3. Auto-assign another electrical task
4. Verify each department maintains separate rotation

## Best Practices

1. **Regular Monitoring**: Check assignment statistics to ensure fair distribution
2. **Availability Management**: Keep staff availability status updated
3. **Manual Override**: Use manual assignment for urgent/special cases
4. **Pointer Reset**: Reset pointers when staff roster changes significantly
5. **Department Accuracy**: Ensure tasks have correct category/department tags

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Same staff always assigned | Only one staff available | Add more staff to department |
| Assignments skip staff | Staff marked unavailable | Check availability status |
| Pointer doesn't persist | SharedPreferences error | Check app permissions |
| Wrong department assigned | Task category mismatch | Verify category mapping |

## Future Enhancements

Potential improvements:

- [ ] Workload-aware assignment (check current task count)
- [ ] Skill-based routing (match task requirements)
- [ ] Time-zone aware scheduling
- [ ] Load balancing across departments
- [ ] Priority-based assignment
- [ ] Staff preference system
- [ ] Absence/vacation handling
- [ ] Real-time availability sync

## Support

For issues or questions:
1. Check error logs in console
2. Review API endpoint responses
3. Verify staff and task data structure
4. Check SharedPreferences keys

## License

This system is part of the FacilityFix application.
