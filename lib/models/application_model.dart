class ApplicationModel {
  final int? id;
  final int jobId;
  final String applicantId;
  final String applicationStatus;
  final DateTime? dateApplied;

  ApplicationModel({
    this.id,
    required this.jobId,
    required this.applicantId,
    this.applicationStatus = 'Pending',
    this.dateApplied,
  });

  // Create from JSON
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['application_id'],
      jobId: json['job_id'],
      applicantId: json['applicant_id'],
      applicationStatus: json['application_status'] ?? 'Pending',
      dateApplied: json['date_applied'] != null
          ? DateTime.parse(json['date_applied'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'application_id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'application_status': applicationStatus,
      if (dateApplied != null) 'date_applied': dateApplied!.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  ApplicationModel copyWith({
    int? id,
    int? jobId,
    String? applicantId,
    String? applicationStatus,
    DateTime? dateApplied,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      dateApplied: dateApplied ?? this.dateApplied,
    );
  }
}