# Round-Robin Assignment System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ADMIN WEB INTERFACE                          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Concern Slip │  │ Job Service  │  │ Work Order   │          │
│  │    Tasks     │  │    Tasks     │  │    Tasks     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         └──────────────────┼──────────────────┘                  │
│                            │                                      │
│                    ┌───────▼────────┐                            │
│                    │ Assign Staff   │                            │
│                    │    Dialog      │                            │
│                    └───────┬────────┘                            │
│                            │                                      │
│              ┌─────────────┼─────────────┐                       │
│              │                            │                       │
│     ┌────────▼─────────┐      ┌─────────▼────────┐             │
│     │  Manual Assign   │      │   Auto-Assign    │             │
│     │  (Green Button)  │      │ (Orange Button)  │             │
│     └────────┬─────────┘      └─────────┬────────┘             │
│              │                           │                       │
└──────────────┼───────────────────────────┼───────────────────────┘
               │                           │
               │                           │
┌──────────────▼───────────────────────────▼───────────────────────┐
│                  ROUND-ROBIN SERVICE LAYER                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  RoundRobinAssignmentService                            │    │
│  │                                                           │    │
│  │  Methods:                                                │    │
│  │  • autoAssignTask()          - Main assignment method   │    │
│  │  • getNextStaffForDepartment() - Get next in rotation   │    │
│  │  • previewNextAssignment()    - Preview without assign  │    │
│  │  • resetDepartmentPointer()   - Reset single dept       │    │
│  │  • resetAllPointers()         - Reset all depts         │    │
│  │  • getAssignmentStatistics()  - Get current state       │    │
│  └─────────────────┬───────────────────────────────────────┘    │
│                    │                                              │
│                    │                                              │
│  ┌─────────────────▼───────────────────────────────────────┐    │
│  │            DEPARTMENT POINTER MANAGER                    │    │
│  │                                                           │    │
│  │  Electrical:   Position 2  ───►  [S1] [S2] [S3] [S4]   │    │
│  │  Plumbing:     Position 0  ───►  [S1] [S2] [S3]        │    │
│  │  HVAC:         Position 1  ───►  [S1] [S2]             │    │
│  │  Carpentry:    Position 3  ───►  [S1] [S2] [S3] [S4]   │    │
│  │  Maintenance:  Position 0  ───►  [S1] [S2] [S3] [S4]   │    │
│  │                                                           │    │
│  │  Storage: SharedPreferences                              │    │
│  │  Format: rr_pointer_{department} : integer              │    │
│  └─────────────────┬───────────────────────────────────────┘    │
│                    │                                              │
└────────────────────┼──────────────────────────────────────────────┘
                     │
                     │
┌────────────────────▼──────────────────────────────────────────────┐
│                     API SERVICE LAYER                              │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  ApiService                                               │    │
│  │                                                            │    │
│  │  • getStaffMembers(dept, availableOnly)                  │    │
│  │  • assignStaffToConcernSlip(id, staffId)                 │    │
│  │  • assignStaffToJobService(id, staffId)                  │    │
│  │  • assignStaffToWorkOrder(id, staffId, note)             │    │
│  └──────────────────┬───────────────────────────────────────┘    │
│                     │                                              │
└─────────────────────┼──────────────────────────────────────────────┘
                      │
                      │ HTTP Requests
                      │
┌─────────────────────▼──────────────────────────────────────────────┐
│                    BACKEND API                                      │
│                                                                     │
│  Endpoints:                                                         │
│  • GET  /users/staff?department={dept}&available_only=true         │
│  • PATCH /concern-slips/{id}/assign-staff                          │
│  • PATCH /job-services/{id}/assign                                 │
│  • PATCH /work-orders/{id}/assign                                  │
│                                                                     │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      │
┌─────────────────────▼───────────────────────────────────────────────┐
│                   FIREBASE FIRESTORE                                 │
│                                                                      │
│  Collections:                                                        │
│  • users (staff members with departments)                           │
│  • concern_slips (with assigned_to field)                           │
│  • job_services (with assigned_to field)                            │
│  • work_orders (with assigned_to field)                             │
│  • maintenance_tasks (with assigned_to field)                       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Assignment Flow Diagram

```
START: Admin clicks "Auto-Assign"
│
├─► 1. Detect Task Details
│   ├─ Task ID: CS-2025-00123
│   ├─ Task Type: concern_slip
│   └─ Department: electrical
│
├─► 2. Fetch Available Staff
│   │   API: GET /users/staff?department=electrical&available_only=true
│   │
│   └─► Response:
│       [
│         {id: "S1", name: "John Doe"},
│         {id: "S2", name: "Jane Smith"},
│         {id: "S3", name: "Bob Johnson"}
│       ]
│
├─► 3. Get Department Pointer
│   │   SharedPreferences: rr_pointer_electrical = 1
│   │
│   └─► Current position: 1
│
├─► 4. Calculate Next Staff
│   │   Formula: pointer % staff_count
│   │   Calculation: 1 % 3 = 1
│   │
│   └─► Selected: Staff at index 1 = "Jane Smith" (S2)
│
├─► 5. Assign Task
│   │   API: PATCH /concern-slips/CS-2025-00123/assign-staff
│   │   Body: {assigned_to: "S2"}
│   │
│   └─► Response: Success
│
├─► 6. Update Pointer
│   │   New value: (1 + 1) % 3 = 2
│   │   Save: SharedPreferences: rr_pointer_electrical = 2
│   │
│   └─► Next assignment will go to index 2 (Bob Johnson)
│
└─► END: Show success message
    "Auto-assigned to Jane Smith successfully!"
```

## Department Rotation Example

```
ELECTRICAL DEPARTMENT
Staff: [John, Jane, Bob, Alice]

Assignment Sequence:
┌──────────┬──────────┬──────────────┬─────────────┐
│ Task #   │ Pointer  │ Assigned To  │ Next Ptr    │
├──────────┼──────────┼──────────────┼─────────────┤
│ Task 1   │    0     │    John      │     1       │
│ Task 2   │    1     │    Jane      │     2       │
│ Task 3   │    2     │    Bob       │     3       │
│ Task 4   │    3     │    Alice     │     0       │ ◄── Wraps
│ Task 5   │    0     │    John      │     1       │
│ Task 6   │    1     │    Jane      │     2       │
└──────────┴──────────┴──────────────┴─────────────┘

Result: Fair distribution - each staff gets same number of tasks
```

## Multi-Department Isolation

```
┌─────────────────────────────────────────────────────────┐
│  ELECTRICAL (Pointer: 2)                                │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐                        │
│  │ S1 │  │ S2 │  │►S3◄│  │ S4 │  Next: S3              │
│  └────┘  └────┘  └────┘  └────┘                        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  PLUMBING (Pointer: 0)                                  │
│  ┌────┐  ┌────┐  ┌────┐                                │
│  │►S1◄│  │ S2 │  │ S3 │  Next: S1                      │
│  └────┘  └────┘  └────┘                                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  MAINTENANCE (Pointer: 4)                               │
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐  ┌────┐              │
│  │ S1 │  │ S2 │  │ S3 │  │ S4 │  │►S5◄│  Next: S5     │
│  └────┘  └────┘  └────┘  └────┘  └────┘              │
└─────────────────────────────────────────────────────────┘

Each department maintains independent rotation!
```

## State Persistence

```
┌───────────────────────────────────────────────────────┐
│         SHARED PREFERENCES (LOCAL STORAGE)            │
├───────────────────────────────────────────────────────┤
│  Key: rr_pointer_electrical    | Value: 2             │
│  Key: rr_pointer_plumbing       | Value: 0             │
│  Key: rr_pointer_hvac           | Value: 1             │
│  Key: rr_pointer_carpentry      | Value: 3             │
│  Key: rr_pointer_maintenance    | Value: 0             │
│  Key: rr_pointer_security       | Value: 1             │
│  Key: rr_pointer_fire_safety    | Value: 0             │
└───────────────────────────────────────────────────────┘
                        │
                        │ Survives
                        │
                        ▼
┌───────────────────────────────────────────────────────┐
│              APP RESTART / BROWSER REFRESH            │
└───────────────────────────────────────────────────────┘
                        │
                        │ Restored
                        │
                        ▼
┌───────────────────────────────────────────────────────┐
│      Pointers continue from previous positions        │
│         No reset - maintains assignment state         │
└───────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
START: Auto-Assign Request
│
├─► Try: Fetch Staff
│   ├─ Success: Continue
│   └─ Error: "Failed to load staff members"
│       └─► STOP: Show error to user
│
├─► Check: Staff Available?
│   ├─ Yes: Continue
│   └─ No: "No available staff found"
│       └─► STOP: Show error to user
│
├─► Try: Assign Task
│   ├─ Success: Continue
│   └─ Error: "Assignment failed"
│       ├─► Don't increment pointer
│       └─► STOP: Show error to user
│
└─► Success: Update pointer & confirm
    └─► Show: "Auto-assigned to {name}"
```

## Component Interaction

```
┌──────────────────┐
│  AssignStaff     │  User clicks "Auto-Assign"
│  Popup Widget    │
└────────┬─────────┘
         │
         │ Calls autoAssignTask()
         │
         ▼
┌──────────────────┐
│  RoundRobin      │  1. Determine department
│  Assignment      │  2. Get next staff
│  Service         │  3. Call API
└────────┬─────────┘  4. Update pointer
         │
         │ Uses
         │
         ▼
┌──────────────────┐
│   API Service    │  HTTP requests to backend
└────────┬─────────┘
         │
         │ Communicates
         │
         ▼
┌──────────────────┐
│  Backend API     │  Updates Firestore
└──────────────────┘
```

---

**Diagram Legend:**
- `┌─┐` Boxes represent components
- `│` Vertical connections
- `►◄` Current pointer position
- `───►` Data flow direction
- `▼` Process continuation
