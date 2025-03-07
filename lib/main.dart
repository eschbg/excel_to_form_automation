import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:window_size/window_size.dart';

import 'src/bloc/automation_bloc.dart';
import 'src/screen/employee_screen.dart';
import 'system_tray.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình cửa sổ
  setWindowTitle('Quản lý đồng bộ nhân viên');
  setWindowMinSize(const Size(800, 600));
  setWindowFrame(const Rect.fromLTWH(
    100,
    100,
    1200,
    800,
  ));

  initSystemTray();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => AutomationBloc(),
        child: EmployeeScreen(),
      ),
    );
  }
}
