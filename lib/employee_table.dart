import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:read_excel/employee.dart';

import 'employee_dialog.dart';

class EmployeeTable extends StatefulWidget {
  @override
  _EmployeeTableState createState() => _EmployeeTableState();
}

class _EmployeeTableState extends State<EmployeeTable> {
  List<Employee> employees = [];
  final TextEditingController _searchController = TextEditingController();

  Future<List<Employee>> readExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null) return [];

    File file = File(result.files.single.path!);

    // Đọc file Excel
    var bytes = await file.readAsBytes();
    var excel = Excel.decodeBytes(bytes);

    List<Employee> employees = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      for (var row in sheet.rows.skip(1)) {
        // Bỏ qua header
        employees.add(Employee(
          id: row[0]?.value.toString() ?? '',
          name: row[1]?.value.toString() ?? '',
          email: row[2]?.value.toString() ?? '',
          position: row[3]?.value.toString() ?? '',
        ));
      }
    }

    return employees;
  }

  Future<void> exportToExcel(List<Employee> employees) async {
    final excel = Excel.createExcel();
    final sheet = excel['Employees'];

    // Thêm header
    sheet.appendRow(['ID', 'Họ tên', 'Email', 'Chức vụ', 'Đã gửi']);

    // Thêm dữ liệu
    for (var employee in employees) {
      sheet.appendRow([
        employee.id,
        employee.name,
        employee.email,
        employee.position,
        employee.isSent ? 'Đã gửi' : 'Chưa gửi'
      ]);
    }

    // Lưu file
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/employees_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    File(filePath)..writeAsBytes(excel.encode()!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nhân viên'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: () async {
              final newEmployees = await readExcelFile();
              setState(() => employees.addAll(newEmployees));
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => exportToExcel(employees),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Chức vụ')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: _filteredEmployees.map((employee) {
                  return DataRow(cells: [
                    DataCell(Text(employee.id)),
                    DataCell(Text(employee.name)),
                    DataCell(Text(employee.email)),
                    DataCell(Text(employee.position)),
                    DataCell(
                      employee.isSent
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.error, color: Colors.orange),
                    ),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editEmployee(employee),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _deleteEmployee(employee),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          color: Colors.blue,
                          onPressed: () => _sendToServer(employee),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Employee> get _filteredEmployees => employees
      .where((employee) => employee.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
      .toList();

  void _editEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeEditDialog(
        employee: employee,
        onSave: (updatedEmployee) {
          setState(() {
            final index = employees.indexOf(employee);
            employees[index] = updatedEmployee;
          });
        },
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    setState(() => employees.remove(employee));
  }

  Future<void> _sendToServer(Employee employee) async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_API_URL'),
        body: {
          'id': employee.id,
          'name': employee.name,
          'email': employee.email,
          'position': employee.position
        },
      );

      if (response.statusCode == 200) {
        setState(() => employee.isSent = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi thất bại: ${e.toString()}')),
      );
    }
  }
}
