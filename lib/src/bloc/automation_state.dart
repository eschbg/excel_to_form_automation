part of 'automation_bloc.dart';

sealed class AutomationState extends Equatable {
  const AutomationState();

  @override
  List<Object> get props => [];
}

final class AutomationInitial extends AutomationState {}

final class AutomationLoading extends AutomationState {}

final class AutomationSuccess extends AutomationState {
  final ActionType type;
  final List<Employee> data;
  final String itemPerPage;
  final String countStatusData;
  const AutomationSuccess(
    this.type, {
    this.data = const [],
    this.itemPerPage = '0/0',
    this.countStatusData = '',
  });
}

final class AutomationError extends AutomationState {
  final ActionType type;
  final String errMsg;
  const AutomationError({
    required this.type,
    required this.errMsg,
  });
}

enum ActionType {
  import,
  export,
  add,
  delete,
  edit,
  upload,
  schedule,
  loadMore;

  String toString() {
    if (this == export) {
      return 'Xuất dữ liệu';
    } else if (this == add) {
      return 'Thêm dữ liệu';
    } else if (this == delete) {
      return 'Xoá dữ liệu';
    } else if (this == edit) {
      return 'Chỉnh sửa dữ liệu';
    } else if (this == upload) {
      return 'Gửi dữ liệu';
    } else {
      return '';
    }
  }
}
