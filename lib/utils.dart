import 'package:file_picker/file_picker.dart';

class Utils {
  static Future<String?> getSavePath() async {
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file Excel',
      fileName:
          'employees_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );
  }
}
