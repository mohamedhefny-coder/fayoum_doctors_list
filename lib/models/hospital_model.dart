import 'package:flutter/foundation.dart';

@immutable
class HospitalModel {
  final String id;
  final String name;
  final String? imageAsset;
  final String? address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? ratingCount;
  final List<String> services;

  const HospitalModel({
    required this.id,
    required this.name,
    this.imageAsset,
    this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
    this.services = const [],
  });

  bool get hasLocation => latitude != null && longitude != null;
}
