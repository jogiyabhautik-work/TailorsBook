class TemplateModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? fittingStyle;
  final String? stitchingNotes;
  final Map<String, dynamic> measurements;
  final bool isPublic;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.fittingStyle,
    this.stitchingNotes,
    this.measurements = const {},
    this.isPublic = false,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      fittingStyle: json['fitting_style'] as String?,
      stitchingNotes: json['stitching_notes'] as String?,
      measurements: json['measurements'] != null 
          ? Map<String, dynamic>.from(json['measurements'])
          : {},
      isPublic: json['is_public'] as bool? ?? false,
      downloadCount: json['download_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'fitting_style': fittingStyle,
      'stitching_notes': stitchingNotes,
      'measurements': measurements,
      'is_public': isPublic,
      'download_count': downloadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TemplateModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? fittingStyle,
    String? stitchingNotes,
    Map<String, dynamic>? measurements,
    bool? isPublic,
    int? downloadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      fittingStyle: fittingStyle ?? this.fittingStyle,
      stitchingNotes: stitchingNotes ?? this.stitchingNotes,
      measurements: measurements ?? this.measurements,
      isPublic: isPublic ?? this.isPublic,
      downloadCount: downloadCount ?? this.downloadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
