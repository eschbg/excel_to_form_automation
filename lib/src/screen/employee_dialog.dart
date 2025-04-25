import 'package:flutter/material.dart';
import 'package:read_excel/extensions.dart';

import '../model/employee.dart';

class EmployeeEditDialog extends StatefulWidget {
  final Employee employee;
  final Function(Employee) onSave;

  const EmployeeEditDialog(
      {super.key, required this.employee, required this.onSave});

  @override
  State<EmployeeEditDialog> createState() => _EmployeeEditDialogState();
}

class _EmployeeEditDialogState extends State<EmployeeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController cccdController = TextEditingController();
  ValueNotifier<DateTime>? effectiveStartDate;
  ValueNotifier<DateTime>? effectiveEndDate;
  ValueNotifier<DateTime>? birthDay;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    genderController = TextEditingController(text: widget.employee.gender);
    addressController = TextEditingController(text: widget.employee.address);
    cccdController = TextEditingController(text: widget.employee.cccd);
    effectiveStartDate =
        ValueNotifier<DateTime>(widget.employee.efectiveStartDate);
    effectiveEndDate = ValueNotifier<DateTime>(widget.employee.efectiveEndDate);
    birthDay = ValueNotifier<DateTime>(widget.employee.birthDay);
  }

  @override
  Widget build(BuildContext context) {
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
              controller: genderController,
              decoration: InputDecoration(labelText: 'Giới tính'),
              validator: (value) =>
                  value!.isEmpty ? 'Vui lòng nhập giới tính' : null,
            ),
            _effectiveDateField(
              onTap: () async {
                birthDay?.value = await showDatePicker(
                      context: context,
                      initialDate: widget.employee.birthDay,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    ) ??
                    widget.employee.birthDay;
                setState(() {});
              },
              label: 'Ngày sinh',
              value: birthDay!.value.formatToYmd(),
            ),
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Địa chỉ'),
              validator: (value) =>
                  value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
            ),
            TextFormField(
              controller: cccdController,
              decoration: InputDecoration(labelText: 'CCCD'),
              validator: (value) =>
                  value!.isEmpty ? 'Vui lòng nhập CCCD' : null,
            ),
            _effectiveDateField(
              onTap: () async {
                effectiveStartDate?.value = await showDatePicker(
                      context: context,
                      initialDate: widget.employee.efectiveStartDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    ) ??
                    widget.employee.efectiveStartDate;
                setState(() {});
              },
              label: 'Ngày cấp',
              value: effectiveStartDate!.value.formatToYmd(),
            ),
            _effectiveDateField(
              onTap: () async {
                effectiveEndDate?.value = await showDatePicker(
                      context: context,
                      initialDate: widget.employee.efectiveEndDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    ) ??
                    widget.employee.efectiveEndDate;
                setState(() {});
              },
              label: 'Có giá trị đến',
              value: effectiveEndDate!.value.formatToYmd(),
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
              widget.onSave(Employee(
                name: nameController.text,
                gender: genderController.text,
                birthDay: birthDay!.value,
                address: addressController.text,
                cccd: cccdController.text,
                efectiveStartDate: effectiveStartDate!.value,
                efectiveEndDate: effectiveEndDate!.value,
                status: widget.employee.status,
              ));
              Navigator.pop(context);
            }
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }

  Widget _effectiveDateField({
    required VoidCallback onTap,
    required String label,
    required String value,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          Divider(
            thickness: 1.5,
            color: Colors.black26,
          )
        ],
      ),
    );
  }
}
