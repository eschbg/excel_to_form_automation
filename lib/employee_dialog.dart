import 'package:flutter/material.dart';

import 'employee.dart';

class EmployeeEditDialog extends StatelessWidget {
  final Employee employee;
  final Function(Employee) onSave;

  EmployeeEditDialog({required this.employee, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: employee.name);
    final TextEditingController emailController =
        TextEditingController(text: employee.email);
    final TextEditingController positionController =
        TextEditingController(text: employee.position);

    return AlertDialog(
      title: Text('Chỉnh sửa thông tin'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Họ tên'),
              validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) => value!.isEmpty || !value.contains('@')
                  ? 'Email không hợp lệ'
                  : null,
            ),
            TextFormField(
              controller: positionController,
              decoration: InputDecoration(labelText: 'Chức vụ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              onSave(Employee(
                id: employee.id,
                name: nameController.text,
                email: emailController.text,
                position: positionController.text,
                isSent: employee.isSent,
              ));
              Navigator.pop(context);
            }
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
