import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;

import 'package:read_excel/employee.dart';

import 'employee_dialog.dart';
import 'utils.dart';

class EmployeeTable extends StatefulWidget {
  const EmployeeTable({super.key});

  @override
  State<EmployeeTable> createState() => _EmployeeTableState();
}

class _EmployeeTableState extends State<EmployeeTable> {
  final _urlFormKey = GlobalKey<FormState>();
  String? url;

  List<Employee> employees = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _scheduledTask;

  final controller = StreamController<Employee>();

  static Future<List<Employee>> _parseExcelInBackground(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];
    int processedCount = 0;

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      final totalRows = sheet.rows.length;

      for (int i = 1; i < totalRows; i += 100) {
        final end = i + 100 < totalRows ? i + 100 : totalRows;
        final chunk = sheet.rows.skip(i).take(100);
        for (var row in chunk) {
          employees.add(Employee(
            id: row[0]?.value.toString() ?? '',
            name: row[1]?.value.toString() ?? '',
            email: row[2]?.value.toString() ?? '',
            position: row[3]?.value.toString() ?? '',
          ));
        }
        processedCount += chunk.length;
        debugPrint('Đã xử lý $processedCount/$totalRows dòng');
        await Future.delayed(Duration(milliseconds: 50)); // Giảm tải UI
      }
    }
    return employees;
  }

  Future<List<Employee>> readExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null) return [];

    File file = File(result.files.single.path!);

    // Đọc file Excel
    var bytes = await file.readAsBytes();

    return await compute(_parseExcelInBackground, bytes);
  }

  Future<void> uploadExcel() async {
    final newEmployees = await readExcelFile();
    setState(() {
      employees.clear();
      employees.addAll(newEmployees);
    });
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
    final savePath = await Utils.getSavePath();
    if (savePath != null) {
      File(savePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);
    }
  }

  void _scheduleDailyTask() {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 10);
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    _scheduledTask = Timer.periodic(Duration(minutes: 1), (timer) {
      if (DateTime.now().hour == 10 && DateTime.now().minute == 5) {
        // _sendAllData();
        print('-----AUTO SCHEDULE-----');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleDailyTask();
  }

  @override
  void dispose() {
    super.dispose();
    _scheduledTask?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nhân viên'),
        actions: [
          iconAction(
            'Import',
            Icon(
              Icons.upload_file,
              color: Colors.green,
            ),
            uploadExcel,
          ),
          SizedBox(width: 10),
          iconAction(
            'Export',
            Icon(Icons.download, color: Colors.blue),
            () => exportToExcel(employees),
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width * 0.6,
                minWidth: size.width * 0.4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _editUrl((value) => setState(() => url = value));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                url != null && url!.trim().isNotEmpty
                                    ? url!
                                    : 'Nhập URL',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(width: 20),
                            Icon(
                              Icons.save,
                              color: Colors.blueAccent,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
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
      ),
    );
  }

  Widget iconAction(String label, Icon icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF3C3D37),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            icon,
          ],
        ),
      ),
    );
  }

  List<Employee> get _filteredEmployees => employees
      .where((employee) => employee.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
      .toList();

  //ACTIONS EMPLOYEE
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

  //Edit URL
  void _editUrl(Function(String) onSave) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa thông tin'),
        content: Form(
          key: _urlFormKey,
          child: TextFormField(
            controller: urlController,
            decoration: InputDecoration(labelText: 'URL'),
            validator: (value) => value!.isEmpty ? 'Vui lòng nhập URL' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_urlFormKey.currentState!.validate()) {
                Navigator.pop(context);
                onSave(urlController.text);
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  //Request to server
  Future<void> _sendToServer(Employee employee) async {
    try {
      if (url == null || url!.isEmpty) return;

      final response = await http.post(
        Uri.parse(url!),
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
      await FlutterPlatformAlert.showAlert(
        windowTitle: 'This ia title',
        text: 'This is body',
        alertStyle: AlertButtonStyle.yesNoCancel,
        iconStyle: IconStyle.information,
      );
    }
  }
}
