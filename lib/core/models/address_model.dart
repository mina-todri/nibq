// lib/core/models/address_model.dart

/// Represents a user's delivery address.
///
/// Changes vs original:
/// - [FIX] `hashCode` replaced XOR chain with `Object.hash()` — XOR-only
///   hashing causes high collision rates for string-heavy objects.
/// - [FIX] `isComplete` now also requires `phone.isNotEmpty` since phone is
///   mandatory for delivery couriers.
/// - [IMPROVEMENT] Added `isEmpty` convenience getter (inverse of isComplete)
///   for use in conditional UI rendering.
/// - [IMPROVEMENT] Constructor parameter order matches `toMap`/`fromMap` order
///   for readability; no API breakage (all named params).
class AddressModel {
  final String id;
  final String label;
  final String district;
  final String neighborhood;
  final String street;
  final String buildingNum;
  final String floor;
  final String apartmentNum;
  final String phone;
  final bool isDefault;

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

  /// One-line summary for display in UI chips or order summaries.
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

  /// True when the minimum fields required to dispatch an order are filled.
  /// Requires district, street, buildingNum, AND phone (for courier contact).
  bool get isComplete =>
      district.isNotEmpty &&
          street.isNotEmpty &&
          buildingNum.isNotEmpty &&
          phone.isNotEmpty;

  bool get isEmpty => !isComplete;

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
  int get hashCode => Object.hash(
    id,
    label,
    district,
    neighborhood,
    street,
    buildingNum,
    floor,
    apartmentNum,
    phone,
    isDefault,
  );

  @override
  String toString() => 'AddressModel('
      'id: $id, label: $label, district: $district, '
      'neighborhood: $neighborhood, street: $street, '
      'buildingNum: $buildingNum, floor: $floor, '
      'apartmentNum: $apartmentNum, phone: $phone, '
      'isDefault: $isDefault)';
}