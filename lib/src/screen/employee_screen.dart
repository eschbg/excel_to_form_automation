import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:read_excel/src/bloc/automation_bloc.dart';

import 'package:read_excel/src/model/employee.dart';
import 'package:read_excel/src/shared_pref.dart';
import 'package:windows_toast/windows_toast.dart';

import '../constants.dart';
import 'employee_dialog.dart';
import 'employee_list_item.dart';
import 'restart.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen>
    with AutomaticKeepAliveClientMixin {
  static const Color _bgColor = Color(0xFFF5EFFF);

  final _urlFormKey = GlobalKey<FormState>();
  String url =
      'https://m.luxshare-ict.com/hr/idcardcollectforvnintroducer.html?introducer=Galaxy-241112';
  String _itemPerPage = '';

  final List<Employee> _dataDisplay = [];

  final TextEditingController _searchController = TextEditingController();
  Timer? _scheduledTask;
  Timer? _searchDebounce;

  final _scrollController = ScrollController();

  List<Employee> get _dataFilter => _dataDisplay
      .where((employee) => employee.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase()))
      .toList();

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<AutomationBloc>().add(LoadMore());
    }
  }

  void _scheduleNextRun() async {
    final timeSchedule =
        (await SharedPref.getData(SharedConstants.time) ?? '0').toString();

    final now = DateTime.now();
    var timeConfig =
        DateTime(now.year, now.month, now.day, int.parse(timeSchedule), 00);

    // Nếu hiện tại đã qua thời gian cấu hình, lên lịch cho ngày mai
    if (now.isAfter(timeConfig)) {
      timeConfig = timeConfig.add(Duration(days: 1));
    }

    final durationUntilNextRun = timeConfig.difference(now);

    // Lên lịch gửi dữ liệu
    _scheduledTask = Timer(durationUntilNextRun, () {
      context
          .read<AutomationBloc>()
          .add(SendData(url: url, employees: [], isSchedule: true));
      _scheduleNextRun(); // Lên lịch cho lần gửi tiếp theo
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _scheduleNextRun();
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        title: Text('Quản lý đồng bộ nhân viên'.toUpperCase()),
        actions: [
          iconAction(
            'Nhập dữ liệu',
            Icon(
              Icons.upload_file,
              color: Colors.green,
            ),
            () {
              context.read<AutomationBloc>().add(Import());
            },
          ),
          SizedBox(width: 10),
          iconAction(
            'Xuất dữ liệu',
            Icon(Icons.download, color: Colors.blue),
            () {
              context.read<AutomationBloc>().add(Export());
            },
          ),
          SizedBox(width: 10),
          iconAction(
            '',
            Icon(Icons.settings, color: Colors.blue),
            () {
              _editTimeSchedule((value) {
                context.read<AutomationBloc>().add(SetTimeSchedule(value));
              });
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: BlocConsumer<AutomationBloc, AutomationState>(
          listener: (context, state) {
            if (state is AutomationSuccess) {
              if (state.type == ActionType.loadMore) {
                setState(() {
                  _itemPerPage = state.itemPerPage;
                  _dataDisplay.clear();
                  _dataDisplay.addAll(state.data);
                });
              }
              if (state.type == ActionType.add ||
                  state.type == ActionType.edit ||
                  state.type == ActionType.delete) {
                WindowsToast.show(
                    '${state.type.toString()} thành công!', context, 30,
                    toastColor: Colors.green,
                    textStyle: TextStyle(color: Colors.white));
              }
              if (state.type == ActionType.upload) {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Thông báo!',
                  text: state.countStatusData,
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.information,
                );
              }
              if (state.type == ActionType.schedule) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Thông báo'),
                    content: Text(
                        'Bạn cần khởi động lại ứng dụng sau khi cài đặt thời gian!'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            WidgetRebirth.createRebirth(context: context);
                          },
                          child: Text('Khởi động lại'))
                    ],
                  ),
                );
              }
            } else if (state is AutomationError) {
              if (state.type == ActionType.add ||
                  state.type == ActionType.edit ||
                  state.type == ActionType.delete) {
                FlutterPlatformAlert.showAlert(
                  windowTitle: 'Thông báo!',
                  text: '${state.type.toString()} thất bại!',
                  alertStyle: AlertButtonStyle.ok,
                  iconStyle: IconStyle.information,
                );
              }
            }
          },
          listenWhen: (previous, current) => current != previous,
          builder: (context, state) {
            return Stack(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    right: 8.0, bottom: 8),
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
                                        url.trim().isNotEmpty
                                            ? url
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
                                _searchDebounce = Timer(
                                    const Duration(milliseconds: 300), () {
                                  setState(() {});
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '*** Những nhân viên có trạng thái gửi THÀNH CÔNG sẽ không được thực hiện lại ở những lần tiếp theo ***',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          iconAction(
                            'Thêm nhân viên',
                            Icon(Icons.add, color: Colors.blue),
                            () {
                              _actionsEmployee(context, employee: null);
                            },
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
                            child: _labelTable(FieldNameConstants.index),
                          ),
                          Flexible(
                            flex: 3,
                            child: _labelTable(FieldNameConstants.name),
                          ),
                          Flexible(
                            flex: 1,
                            child: _labelTable(FieldNameConstants.gender),
                          ),
                          Flexible(
                            flex: 2,
                            child: _labelTable(FieldNameConstants.birthday),
                          ),
                          Flexible(
                            flex: 4,
                            child: _labelTable(FieldNameConstants.address),
                          ),
                          Flexible(
                            flex: 2,
                            child: _labelTable(FieldNameConstants.cccd),
                          ),
                          Flexible(
                            flex: 2,
                            child: _labelTable(FieldNameConstants.startDate),
                          ),
                          Flexible(
                            flex: 2,
                            child: _labelTable(FieldNameConstants.expireDate),
                          ),
                          Flexible(
                            flex: 2,
                            child: _labelTable(FieldNameConstants.action),
                          ),
                          Flexible(
                            flex: 1,
                            child: _labelTable(FieldNameConstants.isSent),
                          ),
                          Flexible(
                            flex: 3,
                            child: _labelTable(FieldNameConstants.note),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _dataDisplay.isEmpty
                          ? Center(
                              child: Text(
                                'Không có dữ liệu!',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _dataFilter.length,
                              itemBuilder: (context, index) {
                                final employee = _dataFilter[index];
                                final isLastElement =
                                    index == _dataFilter.length - 1;
                                final isEven = index % 2 == 0;
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: isLastElement ? 50 : 0),
                                  padding: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isEven
                                        ? Color(0xFFF5F5F5)
                                        : Colors.white,
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFEAEAEA))),
                                  ),
                                  child: EmployeeListItem(
                                    employee: employee,
                                    index: index,
                                    onEdit: () => _actionsEmployee(context,
                                        employee: employee),
                                    onDelete: () => _deleteEmployee(employee),
                                    onSend: () => context
                                        .read<AutomationBloc>()
                                        .add(SendData(
                                          url: url,
                                          employees: [employee],
                                        )),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (_itemPerPage.isNotEmpty && _searchController.text.isEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Text(
                        _itemPerPage,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                if (state is AutomationLoading)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration:
                        BoxDecoration(color: Colors.black.withAlpha(45)),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (url.trim().isEmpty) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    'Thông báo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Bạn phải nhập URL',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Đồng ý'),
                    ),
                  ],
                );
              },
            );
          } else {
            context
                .read<AutomationBloc>()
                .add(SendData(url: url, employees: [], isSentAll: true));
          }
        },
        tooltip: 'Gửi tất cả',
        child: Icon(
          Icons.send,
          color: Colors.blueAccent,
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

  //ACTIONS EMPLOYEE
  void _actionsEmployee(BuildContext contextBuilder, {Employee? employee}) {
    showDialog(
      context: contextBuilder,
      builder: (context) => BlocProvider<AutomationBloc>.value(
        value: AutomationBloc(),
        child: EmployeeEditDialog(
          employee: employee ??
              Employee(
                name: '',
                gender: '',
                birthDay: DateTime.now(),
                address: '',
                cccd: '',
                efectiveStartDate: DateTime.now(),
                efectiveEndDate: DateTime.now(),
              ),
          onSave: (updatedEmployee) {
            if (employee != null) {
              final index = _dataDisplay.indexOf(employee);
              contextBuilder
                  .read<AutomationBloc>()
                  .add(Edit(index: index, employee: updatedEmployee));
            } else {
              contextBuilder
                  .read<AutomationBloc>()
                  .add(Add(employee: updatedEmployee));
            }
          },
        ),
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    context.read<AutomationBloc>().add(Delete(employee: employee));
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

  //Edit Time Schedule
  void _editTimeSchedule(Function(String) onSave) async {
    final scheduleController = TextEditingController();

    final timerSchedulePref =
        await SharedPref.getData(SharedConstants.time) ?? '0';
    final timeToInt = int.parse(timerSchedulePref);
    final conditionDescription = timeToInt >= 0 && timeToInt <= 10
        ? 'Sáng'
        : timeToInt > 10 && timeToInt <= 14
            ? 'Trưa'
            : timeToInt > 14 && timeToInt <= 18
                ? 'Chiều'
                : 'Tối';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa thời gian (theo giờ)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Thời gian đồng bộ lên hệ thống hiện tại lúc: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  '$timerSchedulePref giờ $conditionDescription',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            Form(
              key: _urlFormKey,
              child: TextFormField(
                controller: scheduleController,
                decoration: InputDecoration(labelText: 'Nhập thời gian'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập' : null,
              ),
            ),
          ],
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
                onSave(scheduleController.text);
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
