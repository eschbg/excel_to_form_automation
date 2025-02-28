import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'cubit/excel_action_cubit.dart';
import 'employee.dart';
import 'employee_dialog.dart';
import 'employee_list_item.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  PagingState<int, Employee> _pagingState = PagingState();

  late final _pagingController = PagingController<int, Employee>(
    getNextPageKey: (state) => (state.keys?.last ?? 0) + 1,
    fetchPage: (pageKey) => context.read<ExcelImportCubit>().getAllEmployee(),
  );

  // void fetchNextPage() async {
  //   if (_pagingState.isLoading) return;
  //   await Future.value();

  //   setState(() {
  //     _pagingState = _pagingState.copyWith(isLoading: true, error: null);
  //   });

  //   try {
  //     final newKey = (_pagingState.keys?.last ?? 0) + 1;
  //     await context.read<ExcelImportCubit>().loadMore(newKey);
  //   } catch (error) {
  //     setState(() {
  //       _pagingState = _pagingState.copyWith(
  //         error: error,
  //         isLoading: false,
  //       );
  //     });
  //   }
  // }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            () => context.read<ExcelImportCubit>().loadExcel(),
          ),
          SizedBox(width: 10),
          iconAction(
            'Export',
            Icon(Icons.download, color: Colors.blue),
            () => context.read<ExcelImportCubit>().exportToExcel(),
          ),
        ],
      ),
      body: BlocListener<ExcelImportCubit, ExcelImportState>(
        listener: (context, state) {
          if (state is ExcelImportLoading) {
            showDialog(
              context: context,
              builder: (context) => Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          }
          if (state is ExcelImportLoaded) {
            // if (state.isLastPage) {
            //   setState(() {
            //     _pagingState = _pagingState.copyWith(
            //       pages: [...?_pagingState.pages, state.employees],
            //       keys: [...?_pagingState.keys, state.nextPageKey ?? 0],
            //       hasNextPage: !state.isLastPage,
            //       isLoading: false,
            //     );
            //   });
            // } else {
            //   //
            // }
          } else if (state is ExcelDeleteSuccess) {
            print('HELLO WORLD');
          } else if (state is ExcelSentSuccess) {
          } else {}
        },
        child: PagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) {
              return PagedListView<int, Employee>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<Employee>(
                  itemBuilder: (context, employee, index) => EmployeeListItem(
                    employee: employee,
                    index: index,
                    onEdit: () => _showEditDialog(context, employee),
                    onDelete: () =>
                        context.read<ExcelImportCubit>().onDeteleData(employee),
                    onSend: () =>
                        context.read<ExcelImportCubit>().onSendData(employee),
                  ),
                  noItemsFoundIndicatorBuilder: (_) => Center(
                    child: Text('Vui lòng chọn file Excel để bắt đầu'),
                  ),
                ),
              );
            }),
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

  void _showEditDialog(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeEditDialog(
        employee: employee,
        onSave: (p0) {},
      ),
    );
  }
}
