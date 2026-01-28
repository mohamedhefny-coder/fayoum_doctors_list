import 'package:flutter/foundation.dart';

@immutable
class LabModel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? ratingCount;
  final String? workingHours;
  final String? offers;
  final String? contracts;
  final List<String> features;
  final Map<String, List<String>> tests; // category -> list of tests

  const LabModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.whatsapp,
    this.email,
    this.latitude,
    this.longitude,
    this.rating,
    this.ratingCount,
    this.workingHours,
    this.offers,
    this.contracts,
    this.features = const [],
    this.tests = const {},
  });

  bool get hasLocation => latitude != null && longitude != null;

  // تحويل من JSON
  factory LabModel.fromJson(Map<String, dynamic> json) {
    return LabModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      rating: json['rating']?.toDouble(),
      ratingCount: json['rating_count'],
      workingHours: json['working_hours'],
      offers: json['offers'],
      contracts: json['contracts'],
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      tests: json['tests'] != null
          ? (json['tests'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            )
          : {},
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'rating_count': ratingCount,
      'working_hours': workingHours,
      'offers': offers,
      'contracts': contracts,
      'features': features,
      'tests': tests,
    };
  }
}
