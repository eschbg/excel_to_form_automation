import 'package:flutter/material.dart';
import 'package:read_excel/extensions.dart';

import '../model/employee.dart';

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
    final isSuccess = employee.status != null && employee.status!.isSuccess;

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.gender,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.birthDay.formatToYmd(),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.address,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.cccd,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.efectiveStartDate.formatToYmd(),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(
              employee.efectiveEndDate.formatToYmd(),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
                IconButton(
                  icon: Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: Icon(isSuccess ? Icons.cloud_done : Icons.cloud_upload),
                  color: isSuccess ? Colors.green : Colors.blue,
                  onPressed: isSuccess ? null : onSend,
                ),
              ],
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Icon(
              Icons.circle_rounded,
              size: 14,
              color: isSuccess ? Colors.green : Colors.orange,
              shadows: <Shadow>[Shadow(color: Colors.grey, blurRadius: 10.0)],
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            alignment: Alignment.center,
            child: Text(employee.status != null && employee.status!.isSuccess
                ? 'Đăng ký thành công'
                : (employee.status?.errMsg ?? '')),
          ),
        ),
      ],
    );
  }
}
