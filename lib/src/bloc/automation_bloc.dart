import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:read_excel/src/screen/employee.dart';

import '../../utils.dart';
import '../constants.dart';

part 'automation_event.dart';
part 'automation_state.dart';

class AutomationBloc extends Bloc<AutomationEvent, AutomationState> {
  AutomationBloc() : super(AutomationInitial()) {
    on<Initial>((event, emit) {});
    on<Import>(_importData);
    on<Export>(_exportData);
    on<LoadMore>(_loadMore);
    on<SendData>(_sendData);
    on<Add>(_addData);
    on<Delete>(_deleteData);
    on<Edit>(_editData);
  }

  late final List<Employee> _dataSource = [];
  late final List<Employee> _displayData = [];
  static const _itemsPerPage = 100;
  int _currentPage = 0;

  Future<void> _importData(Import event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      _currentPage = 0;
      final newEmployees = await Utils.readExcelFile();
      if (newEmployees.isEmpty) {
        emit(AutomationInitial());
      } else {
        _displayData.clear();
        _dataSource.clear();
        _dataSource.addAll(newEmployees);

        add(LoadMore());
      }
    } catch (error) {
      emit(AutomationError(
        type: ActionType.import,
        errMsg: error.toString(),
      ));
    }
  }

  Future<void> _exportData(Export event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Employees'];

      // Thêm header

      sheet.appendRow([
        FieldNameConstants.name,
        FieldNameConstants.gender,
        FieldNameConstants.address,
        FieldNameConstants.cccd,
        FieldNameConstants.startDate,
        FieldNameConstants.expireDate,
      ]);

      // Thêm dữ liệu
      for (var employee in _dataSource) {
        sheet.appendRow([
          employee.name,
          employee.gender,
          employee.address,
          employee.cccd,
          employee.efectiveStartDate,
          employee.efectiveEndDate,
        ]);
      }

      // Lưu file
      final savePath = await Utils.getSavePath();
      if (savePath != null) {
        File(savePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);
      }
      emit(AutomationSuccess(ActionType.export));
    } catch (error) {
      emit(AutomationError(
        type: ActionType.export,
        errMsg: error.toString(),
      ));
    }
  }

  Future<void> _sendData(SendData event, Emitter emit) async {
    // try {
    //   if (url == null || url!.isEmpty) return;

    //   // final response = await http.post(
    //   //   Uri.parse(url!),
    //   //   body: {
    //   //     'id': employee.id,
    //   //     'name': employee.name,
    //   //     'email': employee.email,
    //   //     'position': employee.position
    //   //   },
    //   // );

    //   // if (response.statusCode == 200) {
    //   //   setState(() => employee.isSent = true);
    //   // }
    // } catch (e) {
    //   await FlutterPlatformAlert.showAlert(
    //     windowTitle: 'This ia title',
    //     text: 'This is body',
    //     alertStyle: AlertButtonStyle.yesNoCancel,
    //     iconStyle: IconStyle.information,
    //   );
    // }
  }

  Future<void> _addData(Add event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      _currentPage = 0;
      _displayData.clear();
      _dataSource.add(event.employee);
      emit(AutomationSuccess(ActionType.add));
      add(LoadMore());
    } catch (error) {
      emit(AutomationError(
        type: ActionType.add,
        errMsg: error.toString(),
      ));
    }
  }

  Future<void> _deleteData(Delete event, Emitter emit) async {
    emit(AutomationLoading());
    _currentPage = 0;
    _displayData.clear();
    try {
      print('DATA REMOVE: ${event.employee}');
      _dataSource.removeWhere(
        (element) => element == event.employee,
      );
      print('DATA S: ${_dataSource[0]}');

      emit(AutomationSuccess(ActionType.delete));
      add(LoadMore());
    } catch (error) {
      emit(AutomationError(
        type: ActionType.delete,
        errMsg: error.toString(),
      ));
    }
  }

  Future<void> _editData(Edit event, Emitter emit) async {
    emit(AutomationLoading());
    _displayData.clear();
    _currentPage = 0;
    try {
      _dataSource[event.index] = event.employee;
      add(LoadMore());
    } catch (error) {
      emit(AutomationError(
        type: ActionType.edit,
        errMsg: error.toString(),
      ));
    }
  }

  Future<void> _loadMore(LoadMore event, Emitter emit) async {
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    final takeItem = endIndex > _dataSource.length
        ? _dataSource.length - startIndex
        : _itemsPerPage;
    if (state is! AutomationLoading && startIndex < _dataSource.length) {
      emit(AutomationLoading());
    }
    print('DATA S LM: ${_dataSource[0]}');

    try {
      if (startIndex < _dataSource.length) {
        final newData = _dataSource.skip(startIndex).take(takeItem);

        _displayData.addAll(newData);
        _currentPage++;

        emit(AutomationSuccess(
          ActionType.loadMore,
          data: _displayData,
          itemPerPage:
              '${endIndex < _dataSource.length ? endIndex : _dataSource.length} / ${_dataSource.length}',
        ));
      }
    } catch (error) {
      emit(AutomationError(
        type: ActionType.loadMore,
        errMsg: error.toString(),
      ));
    }
  }
}
