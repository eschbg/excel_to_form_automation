import 'dart:convert';

import 'reponse_model.dart';

class Employee {
  String name;
  String gender;
  DateTime birthDay;
  String address;
  String cccd;
  DateTime efectiveStartDate;
  DateTime efectiveEndDate;
  ResponseModel? status;

  Employee({
    required this.name,
    required this.gender,
    required this.birthDay,
    required this.address,
    required this.cccd,
    required this.efectiveStartDate,
    required this.efectiveEndDate,
    this.status,
  });

  String toString() {
    return 'Name: $name \nGender: $gender \nBirthDay: $birthDay \nAddress: $address \nCCCD: $cccd \nCreated: $efectiveStartDate \nExpire: $efectiveEndDate \nIsSent: ${status.toString()}';
  }

  Employee copyWith({
    String? name,
    String? gender,
    DateTime? birthDay,
    String? address,
    String? cccd,
    DateTime? efectiveStartDate,
    DateTime? efectiveEndDate,
    ResponseModel? status,
  }) =>
      Employee(
        name: name ?? this.name,
        gender: gender ?? this.gender,
        birthDay: birthDay ?? this.birthDay,
        address: address ?? this.address,
        cccd: cccd ?? this.cccd,
        efectiveStartDate: efectiveStartDate ?? this.efectiveStartDate,
        efectiveEndDate: efectiveEndDate ?? this.efectiveEndDate,
        status: status,
      );
}
