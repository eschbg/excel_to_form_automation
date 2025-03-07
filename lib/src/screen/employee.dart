class Employee {
  String name;
  String gender;
  String address;
  String cccd;
  DateTime efectiveStartDate;
  DateTime efectiveEndDate;
  bool isSent;

  Employee({
    required this.name,
    required this.gender,
    required this.address,
    required this.cccd,
    required this.efectiveStartDate,
    required this.efectiveEndDate,
    this.isSent = false,
  });

  String toString() {
    return 'Name: $name \nGender: $gender \nAddress: $address \nCCCD: $cccd \nCreated: $efectiveStartDate \nExpire: $efectiveEndDate \nIsSent: $isSent';
  }
}
