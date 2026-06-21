enum DocumentStatus { approved, reviewing, rejected, pending }

class Documento {
  final String id;
  final String nombre;
  final DocumentStatus status;
  final String? rejectionReason;
  final String? fileUrl;
  final String? fileName;
  final String? uploadedDate;
  final bool optional;

  const Documento({
    required this.id,
    required this.nombre,
    required this.status,
    this.rejectionReason,
    this.fileUrl,
    this.fileName,
    this.uploadedDate,
    this.optional = false,
  });
}
