import 'package:hive/hive.dart';

part 'measurement_template.g.dart';

@HiveType(typeId: 7)
enum TemplateCategory { 
  @HiveField(0)
  ladies, 
  @HiveField(1)
  gents, 
  @HiveField(2)
  custom, 
  @HiveField(3)
  both 
}

@HiveType(typeId: 11)
enum FieldType {
  @HiveField(0)
  number,
  @HiveField(1)
  text
}

@HiveType(typeId: 8)
class MeasurementField extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String label;
  @HiveField(2)
  final String unit; 
  @HiveField(3)
  final FieldType type;

  MeasurementField({
    required this.id,
    required this.label,
    this.unit = 'inch',
    this.type = FieldType.number,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'unit': unit,
      'type': type.name,
    };
  }

  factory MeasurementField.fromMap(Map<String, dynamic> map) {
    return MeasurementField(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      unit: map['unit']?.toString() ?? 'inch',
      type: FieldType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FieldType.number,
      ),
    );
  }
}

@HiveType(typeId: 9)
class ProductTemplate extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final TemplateCategory category;
  @HiveField(3)
  final bool isSystemTemplate;
  @HiveField(4)
  final String? tailorId; 
  @HiveField(5)
  final List<MeasurementField> fields;

  ProductTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.isSystemTemplate = false,
    this.tailorId,
    required this.fields,
  });

  ProductTemplate copyWith({
    String? id,
    String? name,
    List<MeasurementField>? fields,
  }) {
    return ProductTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category,
      isSystemTemplate: false, 
      tailorId: tailorId,
      fields: fields ?? List.from(this.fields),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'tailor_id': tailorId,
      'measurements': fields.map((f) => f.toMap()).toList(),
    };
  }

  factory ProductTemplate.fromMap(Map<String, dynamic> map) {
    return ProductTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Template',
      category: TemplateCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TemplateCategory.custom,
      ),
      isSystemTemplate: false,
      tailorId: map['tailor_id']?.toString(),
      fields: ((map['measurements'] ?? map['fields']) as List?)
              ?.map((f) => MeasurementField.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

final List<ProductTemplate> systemTemplates = [
  // Ladies
  ProductTemplate(
    id: 'sys_blouse',
    name: 'Blouse',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'bust', label: 'Bust'),
      MeasurementField(id: 'under_bust', label: 'Under Bust'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'arm_round', label: 'Arm Round'),
      MeasurementField(id: 'front_neck', label: 'Front Neck Depth'),
      MeasurementField(id: 'back_neck', label: 'Back Neck Depth'),
      MeasurementField(id: 'blouse_length', label: 'Blouse Length'),
      MeasurementField(id: 'waist', label: 'Waist'),
    ],
  ),
  ProductTemplate(
    id: 'sys_kurti',
    name: 'Kurti',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'bust', label: 'Bust'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'kurti_length', label: 'Kurti Length'),
    ],
  ),
  // Gents
  ProductTemplate(
    id: 'sys_shirt',
    name: 'Shirt',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'armhole', label: 'Armhole'),
      MeasurementField(id: 'neck', label: 'Neck'),
      MeasurementField(id: 'shirt_length', label: 'Shirt Length'),
      MeasurementField(id: 'cuff', label: 'Cuff'),
    ],
  ),
  ProductTemplate(
    id: 'sys_pant',
    name: 'Pant',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'thigh', label: 'Thigh'),
      MeasurementField(id: 'pant_length', label: 'Pant Length'),
      MeasurementField(id: 'in_seam', label: 'In-seam'),
      MeasurementField(id: 'bottom', label: 'Bottom'),
    ],
  ),

  // Additional Ladies Templates
  ProductTemplate(
    id: 'sys_salwar',
    name: 'Salwar',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'thigh', label: 'Thigh'),
      MeasurementField(id: 'salwar_length', label: 'Salwar Length'),
      MeasurementField(id: 'calf', label: 'Calf'),
      MeasurementField(id: 'ankle', label: 'Ankle'),
    ],
  ),
  ProductTemplate(
    id: 'sys_lehenga',
    name: 'Lehenga',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'lehenga_length', label: 'Lehenga Length'),
      MeasurementField(id: 'flare', label: 'Flare'),
    ],
  ),
  ProductTemplate(
    id: 'sys_saree_blouse',
    name: 'Saree Blouse',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'bust', label: 'Bust'),
      MeasurementField(id: 'under_bust', label: 'Under Bust'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'front_neck', label: 'Front Neck Depth'),
      MeasurementField(id: 'back_neck', label: 'Back Neck Depth'),
      MeasurementField(id: 'blouse_length', label: 'Blouse Length'),
    ],
  ),
  ProductTemplate(
    id: 'sys_churidar',
    name: 'Churidar',
    category: TemplateCategory.ladies,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'thigh', label: 'Thigh'),
      MeasurementField(id: 'calf', label: 'Calf'),
      MeasurementField(id: 'ankle', label: 'Ankle'),
      MeasurementField(id: 'churidar_length', label: 'Churidar Length'),
    ],
  ),

  // Additional Gents Templates
  ProductTemplate(
    id: 'sys_kurta',
    name: 'Kurta',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'armhole', label: 'Armhole'),
      MeasurementField(id: 'neck', label: 'Neck'),
      MeasurementField(id: 'kurta_length', label: 'Kurta Length'),
    ],
  ),
  ProductTemplate(
    id: 'sys_sherwani',
    name: 'Sherwani',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'armhole', label: 'Armhole'),
      MeasurementField(id: 'neck', label: 'Neck'),
      MeasurementField(id: 'sherwani_length', label: 'Sherwani Length'),
    ],
  ),
  ProductTemplate(
    id: 'sys_blazer',
    name: 'Blazer',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'armhole', label: 'Armhole'),
      MeasurementField(id: 'blazer_length', label: 'Blazer Length'),
    ],
  ),
  ProductTemplate(
    id: 'sys_trouser',
    name: 'Trouser',
    category: TemplateCategory.gents,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'thigh', label: 'Thigh'),
      MeasurementField(id: 'knee', label: 'Knee'),
      MeasurementField(id: 'trouser_length', label: 'Trouser Length'),
      MeasurementField(id: 'bottom', label: 'Bottom'),
      MeasurementField(id: 'rise', label: 'Rise'),
    ],
  ),

  // Unisex / Kids Templates
  ProductTemplate(
    id: 'sys_kids_shirt',
    name: 'Kids Shirt',
    category: TemplateCategory.both,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'shirt_length', label: 'Shirt Length'),
    ],
  ),
  ProductTemplate(
    id: 'sys_kids_pant',
    name: 'Kids Pant',
    category: TemplateCategory.both,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'pant_length', label: 'Pant Length'),
      MeasurementField(id: 'bottom', label: 'Bottom'),
    ],
  ),
  ProductTemplate(
    id: 'sys_jacket',
    name: 'Jacket',
    category: TemplateCategory.both,
    isSystemTemplate: true,
    fields: [
      MeasurementField(id: 'chest', label: 'Chest'),
      MeasurementField(id: 'waist', label: 'Waist'),
      MeasurementField(id: 'hip', label: 'Hip'),
      MeasurementField(id: 'shoulder', label: 'Shoulder'),
      MeasurementField(id: 'sleeve_length', label: 'Sleeve Length'),
      MeasurementField(id: 'jacket_length', label: 'Jacket Length'),
    ],
  ),
];
