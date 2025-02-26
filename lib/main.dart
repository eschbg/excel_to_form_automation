import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'employee_table.dart';

void main() {
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
      home: EmployeeTable(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FilePickerResult? _filePicked;

  Future<void> pickFile() async {
    _filePicked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    log('DATA PATH: ${_filePicked != null ? _filePicked!.files.single.path! : ''}');
  }

  Future<void> importAndSendData() async {
    // Chọn file Excel

    if (_filePicked != null) {
      File file = File(_filePicked!.files.single.path!);

      // Đọc file Excel
      var bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      // Giả sử dữ liệu nằm ở sheet đầu tiên
      var sheet = excel.tables.keys.first;
      var rows = excel.tables[sheet]!.rows;

      // Bỏ qua hàng đầu tiên (tiêu đề)
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];

        // Giả sử cột structure: Tên | Email | SĐT | ...
        String name = row[0]?.value.toString() ?? '';
        String email = row[1]?.value.toString() ?? '';
        String phone = row[2]?.value.toString() ?? '';

        // Gửi dữ liệu lên server
        await sendToServer(
          name: name,
          email: email,
          phone: phone,
        );
      }
    } else {
      // User canceled the picker
    }
  }

  Future<void> sendToServer({
    required String name,
    required String email,
    required String phone,
  }) async {
    const String url = 'YOUR_SERVER_ENDPOINT';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          // Thêm các trường khác
        },
        headers: {
          'Content-Type':
              'application/x-www-form-urlencoded', // Hoặc 'application/json'
          // Thêm headers nếu cần (token, auth...)
        },
      );

      if (response.statusCode == 200) {
        print('Gửi thành công: $name');
      } else {
        print('Lỗi khi gửi ${name}: ${response.body}');
        // Xử lý retry nếu cần
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: pickFile, child: Text('IMPORT')),
            const Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: importAndSendData,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
