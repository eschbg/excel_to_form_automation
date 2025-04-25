import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_size/window_size.dart';

import 'src/bloc/automation_bloc.dart';
import 'src/screen/employee_screen.dart';
import 'src/screen/restart.dart';
import 'system_tray.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình cửa sổ
  setWindowTitle('Quản lý đồng bộ nhân viên');
  setWindowMinSize(const Size(1920, 1080));
  setWindowFrame(const Rect.fromLTWH(
    0,
    0,
    1920,
    1080,
  ));

  initSystemTray();
  runApp(WidgetRebirth(materialApp: const MyApp()));
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
