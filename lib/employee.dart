class Employee {
  String id;
  String name;
  String email;
  String position;
  bool isSent;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    this.isSent = false,
  });
}
