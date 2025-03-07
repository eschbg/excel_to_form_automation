import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static String valueSharedPreferences = 'path';

  // Write DATA
  static Future<bool> saveData(value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setInt(valueSharedPreferences, value);
  }

// Read Data
  static Future getData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(valueSharedPreferences);
  }
}
