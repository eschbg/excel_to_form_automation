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
import 'employee_list_item.dart';
import 'utils.dart';

class EmployeeTable extends StatefulWidget {
  const EmployeeTable({super.key});

  @override
  State<EmployeeTable> createState() => _EmployeeTableState();
}

class _EmployeeTableState extends State<EmployeeTable>
    with AutomaticKeepAliveClientMixin {
  static const _itemsPerPage = 100;

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  final _urlFormKey = GlobalKey<FormState>();
  String? url;

  final ValueNotifier<List<Employee>> _employeesNotifier = ValueNotifier([]);
  final ValueNotifier<List<Employee>> _employeesDisplayNotifier =
      ValueNotifier([]);

  final TextEditingController _searchController = TextEditingController();
  Timer? _scheduledTask;
  Timer? _searchDebounce;

  final _scrollController = ScrollController();

  static Future<List<Employee>> _parseExcelInBackground(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      for (var row in sheet.rows.skip(1)) {
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

  Future<void> _loadMoreData() async {
    if (_isLoading.value ||
        _employeesDisplayNotifier.value.length >=
            _employeesNotifier.value.length) {
      return;
    }

    final sourceList = _searchController.text.isNotEmpty
        ? _filteredEmployees
        : _employeesNotifier.value;

    _isLoading.value = true;

    await Future.delayed(Duration(seconds: 1)); // Giả lập delay

    int startIndex = _currentPage.value * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (startIndex < sourceList.length) {
      List<Employee> newData = sourceList.sublist(
        startIndex,
        endIndex > sourceList.length ? sourceList.length : endIndex,
      );
      _isLoading.value = false;
      _currentPage.value++;
      _employeesDisplayNotifier.value.addAll(newData);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> uploadExcel() async {
    _isLoading.value = true;
    final newEmployees = await readExcelFile();
    _employeesNotifier.value.clear();
    _employeesNotifier.value = newEmployees;
    _isLoading.value = false;
  }

  Future<void> exportToExcel(List<Employee> employees) async {
    final excel = Excel.createExcel();
    final sheet = excel['Employees'];

    // Thêm header
    sheet.appendRow(['ID', 'Họ tên', 'Email', 'Chức vụ', 'Đã gửi']);

    // Thêm dữ liệu
    for (var employee in _employeesNotifier.value) {
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
    _scrollController.addListener(_scrollListener);
    _scheduleDailyTask();
  }

  @override
  void dispose() {
    super.dispose();
    _searchDebounce?.cancel();
    _scheduledTask?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý đồng bộ nhân viên'.toUpperCase()),
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
            () => exportToExcel(_employeesNotifier.value),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: Stack(
          children: [
            Column(
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
                            padding:
                                const EdgeInsets.only(right: 8.0, bottom: 8),
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
                          onChanged: (value) {
                            if (_searchDebounce?.isActive ?? false) {
                              _searchDebounce!.cancel();
                            }
                            _searchDebounce =
                                Timer(const Duration(milliseconds: 300), () {
                              setState(() {});
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Color(0xFF4D4C7D),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _labelTable('STT'),
                      ),
                      Flexible(
                        flex: 3,
                        child: _labelTable('Họ Tên'),
                      ),
                      Flexible(
                        flex: 1,
                        child: _labelTable('Positioned'),
                      ),
                      Flexible(
                        flex: 2,
                        child: _labelTable('Action'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _employeesNotifier,
                    builder: (context, value, child) => ListView.builder(
                      itemCount: _filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = _filteredEmployees[index];
                        return Container(
                          padding: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFFEAEAEA))),
                          ),
                          child: EmployeeListItem(
                            employee: employee,
                            index: index,
                            onEdit: () => _editEmployee(employee),
                            onDelete: () => _deleteEmployee(employee),
                            onSend: () => _sendToServer(employee),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading.value)
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
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

  Widget _labelTable(String label) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  List<Employee> get _filteredEmployees => _employeesNotifier.value
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
            final index = _employeesNotifier.value.indexOf(employee);
            _employeesNotifier.value[index] = updatedEmployee;
          });
        },
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    setState(() => _employeesNotifier.value.remove(employee));
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

  @override
  bool get wantKeepAlive => true;
}
