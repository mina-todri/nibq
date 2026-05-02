// lib/core/models/address_model.dart
// FIXES:
//   1. Added isDefault field — supports "Set as default" feature
//   2. fullAddress is null-safe with non-empty checks

class AddressModel {
  final String id;
  final String label;
  final String district;
  final String neighborhood;
  final String street;
  final String buildingNum;
  final String floor;
  final String apartmentNum;
  final String phone;       // FIX 6: phone required for delivery
  final bool isDefault;     // FIX 3: default address flag

  const AddressModel({
    required this.id,
    required this.label,
    required this.district,
    required this.neighborhood,
    required this.street,
    required this.buildingNum,
    required this.floor,
    required this.apartmentNum,
    this.phone = '',
    this.isDefault = false,
  });

  AddressModel copyWith({
    String? id,
    String? label,
    String? district,
    String? neighborhood,
    String? street,
    String? buildingNum,
    String? floor,
    String? apartmentNum,
    String? phone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      street: street ?? this.street,
      buildingNum: buildingNum ?? this.buildingNum,
      floor: floor ?? this.floor,
      apartmentNum: apartmentNum ?? this.apartmentNum,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'district': district,
      'neighborhood': neighborhood,
      'street': street,
      'buildingNum': buildingNum,
      'floor': floor,
      'apartmentNum': apartmentNum,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      neighborhood: map['neighborhood']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      buildingNum: map['buildingNum']?.toString() ?? '',
      floor: map['floor']?.toString() ?? '',
      apartmentNum: map['apartmentNum']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      isDefault: map['isDefault'] is bool ? map['isDefault'] as bool : false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          district == other.district &&
          neighborhood == other.neighborhood &&
          street == other.street &&
          buildingNum == other.buildingNum &&
          floor == other.floor &&
          apartmentNum == other.apartmentNum &&
          phone == other.phone &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      district.hashCode ^
      neighborhood.hashCode ^
      street.hashCode ^
      buildingNum.hashCode ^
      floor.hashCode ^
      apartmentNum.hashCode ^
      phone.hashCode ^
      isDefault.hashCode;

  @override
  String toString() {
    return 'AddressModel(id: $id, label: $label, district: $district, neighborhood: $neighborhood, street: $street, buildingNum: $buildingNum, floor: $floor, apartmentNum: $apartmentNum, phone: $phone, isDefault: $isDefault)';
  }

  /// One-line summary for display
  String get fullAddress {
    final parts = [
      if (district.isNotEmpty) district,
      if (neighborhood.isNotEmpty) neighborhood,
      if (street.isNotEmpty) street,
      if (buildingNum.isNotEmpty) 'عمارة $buildingNum',
      if (floor.isNotEmpty) 'الدور $floor',
      if (apartmentNum.isNotEmpty) 'شقة $apartmentNum',
    ];
    return parts.join('، ');
  }

  bool get isComplete =>
      district.isNotEmpty &&
      street.isNotEmpty &&
      buildingNum.isNotEmpty;
}
