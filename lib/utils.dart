import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'src/screen/employee.dart';
import 'src/shared_pref.dart';

class Utils {
  static Future<String?> getSavePath() async {
    final path =
        'employees_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    SharedPref.saveData(path);
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file Excel',
      fileName: path,
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
  }

  static Future<List<Employee>> readExcelFile() async {
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

  static Future<List<Employee>> _parseExcelInBackground(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      for (var row in sheet.rows.skip(1)) {
        employees.add(Employee(
          name: row[0]?.value.toString() ?? '',
          gender: row[1]?.value.toString() ?? '',
          address: row[2]?.value.toString() ?? '',
          cccd: row[3]?.value.toString() ?? '',
          efectiveStartDate: _convertToDate(row[4]),
          efectiveEndDate: _convertToDate(row[5]),
        ));
      }
    }
    return employees;
  }

  static DateTime _convertToDate(Data? data) =>
      (data != null && data.value != null)
          ? DateTime.parse(data.value.toString())
          : DateTime.now();

  static void scheduleDailyTask() {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 10);
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    Timer.periodic(Duration(minutes: 1), (timer) {
      if (DateTime.now().hour == 10 && DateTime.now().minute == 5) {
        // _sendAllData();
        print('-----AUTO SCHEDULE-----');
      }
    });
  }
}
