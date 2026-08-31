import 'package:flutter/material.dart';

class StaffManagementScreen extends StatelessWidget {
  final List<Map<String, dynamic>> staffList;

  const StaffManagementScreen({super.key, required this.staffList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: staffList.isEmpty
          ? const Center(child: Text('No staff members'))
          : ListView.builder(
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return ListTile(
                  title: Text(staff['name'] ?? 'Unknown'),
                  subtitle: Text(staff['role'] ?? 'Staff'),
                );
              },
            ),
    );
  }
}
