enum DocumentType {
  aadhaar('aadhaar', 'Aadhaar Card (Govt ID)'),
  tradeCertificate('trade_certificate', 'Trade / Skill Certificate (ITI/NSDC)'),
  cooperativeIdCard('cooperative_id', 'Cooperative Membership Card'),
  policeVerification('police_verification', 'Police Verification Certificate'),
  voterId('voter_id', 'Voter Identity Card'),
  pan('pan', 'Permanent Account Number (PAN)');

  const DocumentType(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static DocumentType fromDbValue(String? value) {
    for (final DocumentType type in DocumentType.values) {
      if (type.dbValue == value) {
        return type;
      }
    }
    return DocumentType.tradeCertificate;
  }
}

class WorkerDocument {
  const WorkerDocument({
    required this.id,
    required this.workerId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    this.fileSize = 0,
    this.mimeType = 'application/octet-stream',
    this.status = 'pending',
    this.createdAt,
    this.downloadUrl,
  });

  final String id;
  final String workerId;
  final DocumentType documentType;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String status;
  final DateTime? createdAt;
  final String? downloadUrl;

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  WorkerDocument copyWith({
    String? id,
    String? workerId,
    DocumentType? documentType,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    String? status,
    DateTime? createdAt,
    String? downloadUrl,
  }) {
    return WorkerDocument(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }

  factory WorkerDocument.fromJson(Map<String, Object?> json) {
    return WorkerDocument(
      id: json['id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      documentType: DocumentType.fromDbValue(json['document_type'] as String?),
      fileName: json['file_name'] as String? ?? 'document',
      filePath: json['file_path'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']! as String) : null,
      downloadUrl: json['download_url'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'worker_id': workerId,
      'document_type': documentType.dbValue,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'status': status,
    };
  }
}
