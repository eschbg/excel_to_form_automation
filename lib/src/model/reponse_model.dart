class ResponseModel {
  final bool isSuccess;
  final String? errMsg;
  final String? data;

  const ResponseModel({required this.isSuccess, this.errMsg, this.data});

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
        isSuccess: json['IsSuccess'],
        errMsg: json['ErrMsg'],
        data: json['Data'],
      );

  String toString() {
    return 'isSuccess: $isSuccess; errMsg: $errMsg; data: $data';
  }
}
