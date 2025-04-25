import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'src/model/employee.dart';
import 'src/shared_pref.dart';

class Utils {
  static Future<String?> getSavePath() async {
    final path =
        'employees_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file Excel',
      fileName: path,
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
  }

  static Future<List<Employee>> filePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    print('================EXCEL IMPORT: $result');

    if (result == null) return [];

    return readExcelFile(result.files.single.path!);
  }

  static Future<List<Employee>> readExcelFile(String path) async {
    File file = File(path);

    // Đọc file Excel
    var bytes = await file.readAsBytes();
    print('================EXCEL IMPORT: $bytes');

    return await compute(_parseExcelInBackground, bytes);
  }

  static Future<List<Employee>> _parseExcelInBackground(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      for (var row in sheet.rows.skip(1)) {
        employees.add(Employee(
          name: row[1]?.value.toString() ?? '',
          gender: row[2]?.value.toString() ?? '',
          birthDay: _convertToDate(row[3]),
          address: row[4]?.value.toString() ?? '',
          cccd: row[5]?.value.toString() ?? '',
          efectiveStartDate: _convertToDate(row[6]),
          efectiveEndDate: _convertToDate(row[7]),
        ));
      }
    }
    print('================EMPLOYEE ISOLATE: $employees');

    return employees;
  }

  static DateTime _convertToDate(Data? data) =>
      (data != null && data.value != null)
          ? DateTime.parse(data.value.toString())
          : DateTime.now();
}
