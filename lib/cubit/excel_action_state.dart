part of 'excel_action_cubit.dart';

class ExcelImportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExcelImportInitial extends ExcelImportState {}

class ExcelImportLoading extends ExcelImportState {}

class ExcelSentSuccess extends ExcelImportState {
  final Employee employee;
  ExcelSentSuccess(this.employee);
}

class ExcelDeleteSuccess extends ExcelImportState {
  final Employee employee;
  ExcelDeleteSuccess(this.employee);
}

// class ExcelError extends ExcelImportState {
//   final String message;
//   ExcelError(this.message);
// }

class ExcelImportError extends ExcelImportState {
  final String message;
  ExcelImportError(this.message);
}

class ExcelImportLoaded extends ExcelImportState {
  final List<Employee> employees;
  final int? nextPageKey;
  final bool isLastPage;
  final int chunkSize;

  ExcelImportLoaded({
    required this.employees,
    required this.nextPageKey,
    required this.isLastPage,
    required this.chunkSize,
  });
}
