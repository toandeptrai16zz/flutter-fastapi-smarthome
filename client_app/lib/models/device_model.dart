// Data model for a device, mirroring the server-side model.
class Device {
  final String id;
  final String name;
  bool status;

  Device({required this.id, required this.name, this.status = false});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
      };
}
