part of 'automation_bloc.dart';

sealed class AutomationEvent extends Equatable {
  const AutomationEvent();

  @override
  List<Object> get props => [];
}

final class Initial extends AutomationEvent {}

final class Import extends AutomationEvent {}

final class Export extends AutomationEvent {}

final class SetTimeSchedule extends AutomationEvent {
  final String time;
  const SetTimeSchedule(this.time);
}

final class LoadMore extends AutomationEvent {
  final String searchText;

  const LoadMore({
    this.searchText = '',
  });
}

final class SendData extends AutomationEvent {
  final String url;
  final List<Employee> employees;
  final bool isSentAll;
  final bool isSchedule;
  const SendData({
    required this.url,
    required this.employees,
    this.isSentAll = false,
    this.isSchedule = false,
  });
}

final class Delete extends AutomationEvent {
  final Employee employee;
  const Delete({required this.employee});
}

final class Edit extends AutomationEvent {
  final int index;
  final Employee employee;

  const Edit({required this.index, required this.employee});
}

final class Add extends AutomationEvent {
  final Employee employee;
  const Add({required this.employee});
}
