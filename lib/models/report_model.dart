class ReportModel {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final String status;
  final List<String> imagePaths;
  final List<Map<String, dynamic>> findings;

  ReportModel({required this.id, required this.vehicleName, required this.plateNumber, 
               required this.status, required this.imagePaths, required this.findings});

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      vehicleName: map['vehicleName'] ?? 'Kendaraan',
      plateNumber: map['plateNumber'] ?? '-',
      status: map['status'] ?? 'Sangat Baik',
      imagePaths: List<String>.from(map['localImagePaths'] ?? []),
      findings: List<Map<String, dynamic>>.from(map['findings'] ?? []),
    );
  }
}