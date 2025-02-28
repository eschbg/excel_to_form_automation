import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:synchronized/synchronized.dart';

import '../employee.dart';

part 'excel_action_state.dart';

class ExcelImportCubit extends Cubit<ExcelImportState> {
  final int _chunkSize = 100;
  final _synchronized = Lock();
  final List<Employee> _allEmployees = [];

  ExcelImportCubit() : super(ExcelImportInitial());

  List<Employee> getAllEmployee() => _allEmployees;

  Future<void> loadExcel() async {
    try {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (file != null) {
        emit(ExcelImportLoading());
        print('PRE LOAD ALL ITEMS FROM EXCEL');

        final data =
            await compute(_parseExcelInBackground, file.files.single.bytes!);
        _allEmployees.clear();
        _allEmployees.addAll(data);
        loadMore(0);
      }
    } catch (e) {
      emit(ExcelImportError(e.toString()));
    }
  }

  Future<void> loadMore(int pageKey) async {
    try {
      final newItems = _allEmployees.skip(pageKey).take(_chunkSize).toList();
      final isLastPage = newItems.length < _chunkSize;

      print('LOAD MORE NEW ITEMS: $newItems');

      emit(ExcelImportLoaded(
        employees: newItems,
        nextPageKey: isLastPage ? null : pageKey + newItems.length,
        isLastPage: isLastPage,
        chunkSize: _chunkSize,
      ));
    } catch (error) {
      emit(ExcelImportError(error.toString()));
    }
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Employees'];

    // Thêm header
    sheet.appendRow(['ID', 'Họ tên', 'Email', 'Chức vụ', 'Đã gửi']);

    // Thêm dữ liệu
    for (var employee in _allEmployees) {
      sheet.appendRow([
        employee.id,
        employee.name,
        employee.email,
        employee.position,
        employee.isSent ? 'Đã gửi' : 'Chưa gửi'
      ]);
    }
  }

  // Future<void> _processFileInIsolate(Uint8List bytes) async {
  //   final receivePort = ReceivePort();
  //   print('Process File In Isolate');

  //   await Isolate.spawn(
  //     _parseExcelData,
  //     [receivePort.sendPort, bytes],
  //   );

  //   await for (var message in receivePort) {
  //     if (message is List<Employee>) {
  //       await _synchronized.synchronized(() async {
  //         for (var i = 0; i < message.length; i += _chunkSize) {
  //           final chunk = message.sublist(
  //               i,
  //               i + _chunkSize > message.length
  //                   ? message.length
  //                   : i + _chunkSize);
  //           _allEmployees.addAll(chunk);

  //           print('ADD Employee');

  //           await Future.delayed(Duration(milliseconds: 50));
  //         }
  //       });
  //       break;
  //     }
  //   }
  // }

  static Future<List<Employee>> _parseExcelInBackground(List<int> bytes) async {
    print('PRE DECODE EXCEL');

    final excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];
    print('LOAD ALL ITEMS FROM EXCEL: $excel');

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

  static void _parseExcelData(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final Uint8List bytes = args[1];

    try {
      final excel = Excel.decodeBytes(bytes);
      final employees = <Employee>[];

      print('ISOLATE: $excel');

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (var row in sheet.rows.skip(1)) {
          employees.add(Employee(
            id: row[0]?.value.toString() ?? '',
            name: row[1]?.value.toString() ?? '',
            email: row[2]?.value.toString() ?? '',
            position: row[3]?.value.toString() ?? '',
          ));
        }
      }

      Isolate.exit(sendPort, employees);
    } catch (e) {
      Isolate.exit(sendPort, <Employee>[]);
    }
  }

  Future<void> onSendData(Employee employee) async {
    try {
      _allEmployees.remove(employee);
      emit(ExcelSentSuccess(employee));
    } catch (e) {
      emit(ExcelImportError('Send failed: ${e.toString()}'));
    }
  }

  Future<void> onDeteleData(Employee employee) async {
    try {
      // await repository.sendToServer(event.employee);
      // final updatedEmployee = event.employee.copyWith(isSent: true);
      // pagingController.itemList = pagingController.itemList
      //     .map((e) => e.id == updatedEmployee.id ? updatedEmployee : e)
      //     .toList();
      emit(ExcelDeleteSuccess(employee));
    } catch (e) {
      emit(ExcelImportError('Send failed: ${e.toString()}'));
    }
  }
}
