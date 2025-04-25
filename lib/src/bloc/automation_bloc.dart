import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:http/http.dart' as http;
import 'package:read_excel/extensions.dart';

import 'package:read_excel/src/model/employee.dart';

import '../../utils.dart';
import '../constants.dart';
import '../model/reponse_model.dart';
import '../shared_pref.dart';

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
    on<SetTimeSchedule>(_setTimeSchedule);
  }

  late final List<Employee> _dataSource = [];
  late final List<Employee> _displayData = [];
  late final List<Employee> _dataSendError = [];
  static const _itemsPerPage = 100;
  int _currentPage = 0;
  var numberSuccess = 0;
  var numberError = 0;

  Future<void> _importData(Import event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      _currentPage = 0;
      final newEmployees = await Utils.filePicker();
      if (newEmployees.isEmpty) {
        print('==========FILE EMPTY');
        emit(AutomationInitial());
      } else {
        print('==========FILE NOT EMPTY');

        _displayData.clear();
        _dataSource.clear();
        _dataSource.addAll(newEmployees);

        add(LoadMore());
      }
    } catch (error) {
      print('==========IMPORT ERROR');

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
      SharedPref.saveData(SharedConstants.path, savePath);
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
    emit(AutomationLoading());
    try {
      numberError = 0;
      numberSuccess = 0;
      List<Employee> data =
          List.from(event.isSentAll ? _dataSource : event.employees);

      if (event.isSchedule) {
        final getPathLocal = await SharedPref.getData(SharedConstants.path);
        data = await Utils.readExcelFile(getPathLocal);
      }

      const int maxConcurrent = 30;
      final completers = <Completer<void>>[];
      for (var user in data) {
        if (user.status != null && user.status!.isSuccess) continue;

        if (completers.length >= maxConcurrent) {
          await Future.any(completers.map((c) => c.future));
          completers.removeWhere((c) => c.isCompleted);
        }

        final completer = Completer<void>();
        completers.add(completer);

        uploadUser(event.url, user)
            .then((_) => completer.complete())
            .catchError((e) {
          print('Failed to upload ${user.name}: $e');
          completer.complete();
        });
      }

      await Future.wait(
          completers.map((c) => c.future)); // Chờ tất cả hoàn thành

      emit(AutomationSuccess(ActionType.upload,
          countStatusData:
              'Đã gửi $numberSuccess thành công, $numberError thất bại'));
      resetData();
      add(LoadMore());
    } catch (e) {
      print('=======ERROR: $e');
      emit(AutomationError(type: ActionType.upload, errMsg: e.toString()));
    }
  }

  Future<void> uploadUser(String url, Employee employee) async {
    final uri = Uri.parse(
        'https://m.luxshare-ict.com/api/HR/IDCardCollection/RegistVN');
    final uriReferer = Uri.parse(url);
    final introducer = uriReferer.queryParameters['introducer'];

    final headers = {
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate, br, zstd',
      'accept-language': 'en,vi;q=0.9',
      'authorization': 'BasicAuth',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
      'content-type': 'application/x-www-form-urlencoded',
      'host': 'm.luxshare-ict.com',
      'origin': 'https://m.luxshare-ict.com',
      'pragma': 'no-cache',
      'referer': url,
      'sec-ch-ua':
          '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"',
      'sec-ch-ua-mobile': '?1',
      'sec-ch-ua-platform': '"Android"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      'user-agent':
          'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.36',
      'x-requested-with': 'XMLHttpRequest',
    };

    print('=======INFO EMPLOYEE: \n${employee.toString()}');
    final body = {
      'name': employee.name,
      'gender': employee.gender,
      'birthday': employee.birthDay.formatToYmdPath(),
      'address': employee.address,
      'iDCode': employee.cccd,
      'efectiveStartDate': employee.efectiveStartDate.formatToYmdPath(),
      'efectiveEndDate': employee.efectiveEndDate.formatToYmdPath(),
      'oldIDCode': '',
      'nation': 'VN',
      'issuanceAuthority': 'VN',
      'dataFrom': 'VN',
      'registedBy': introducer,
      'registedByName': introducer,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: body,
    );
    print('=======BODY INFO EMPLOYEE: \n$body');
    print('[${response.statusCode}] ${response.body}');

    final rsBody = ResponseModel.fromJson(jsonDecode(response.body));

    final index = _dataSource.indexOf(employee);
    _dataSource[index] = employee.copyWith(status: rsBody);
    if (rsBody.isSuccess) {
      numberSuccess++;
    } else {
      numberError++;
    }
  }

  Future<void> _addData(Add event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      resetData();
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
    resetData();
    try {
      _dataSource.removeWhere(
        (element) => element == event.employee,
      );

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
    resetData();
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

  Future<void> _setTimeSchedule(SetTimeSchedule event, Emitter emit) async {
    emit(AutomationLoading());
    try {
      await SharedPref.saveData(SharedConstants.time, event.time);
      emit(AutomationSuccess(ActionType.schedule));
    } catch (error) {
      emit(AutomationError(
        type: ActionType.schedule,
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

    try {
      print('-------START LOADMORE');
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
      print('-------ERROR LOADMORE: $error');
      emit(AutomationError(
        type: ActionType.loadMore,
        errMsg: error.toString(),
      ));
    }
  }

  void resetData() {
    _currentPage = 0;
    _displayData.clear();
  }
}
