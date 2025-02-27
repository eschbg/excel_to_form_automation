import 'package:flutter/material.dart';

import 'employee.dart';

class EmployeeListItem extends StatelessWidget {
  final Employee employee;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  const EmployeeListItem({
    super.key,
    required this.employee,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(employee.name),
      subtitle: Text(employee.position),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.red,
            onPressed: onDelete,
          ),
          IconButton(
            icon: Icon(employee.isSent ? Icons.cloud_done : Icons.cloud_upload),
            color: employee.isSent ? Colors.green : Colors.blue,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
