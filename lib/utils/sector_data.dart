import 'package:flutter/material.dart';

class SectorInfo {
  final String key;
  final String name;
  final String icon;
  final Color color;

  const SectorInfo({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class SectorData {
  SectorData._();

  static const Map<String, SectorInfo> sectors = {
    'banking': SectorInfo(key: 'banking', name: 'Banking', icon: '\u{1F3E6}', color: Color(0xFF0EA5E9)),
    'energy': SectorInfo(key: 'energy', name: 'Energy & Oil', icon: '\u26A1', color: Color(0xFFF59E0B)),
    'cement': SectorInfo(key: 'cement', name: 'Cement', icon: '\u{1F3D7}\uFE0F', color: Color(0xFF8B5CF6)),
    'fertilizer': SectorInfo(key: 'fertilizer', name: 'Fertilizer', icon: '\u{1F33F}', color: Color(0xFF10B981)),
    'tech': SectorInfo(key: 'tech', name: 'Technology', icon: '\u{1F4BB}', color: Color(0xFFEC4899)),
    'textile': SectorInfo(key: 'textile', name: 'Textile', icon: '\u{1F9F5}', color: Color(0xFFF97316)),
    'pharma': SectorInfo(key: 'pharma', name: 'Pharma', icon: '\u{1F48A}', color: Color(0xFF14B8A6)),
    'auto': SectorInfo(key: 'auto', name: 'Automobile', icon: '\u{1F697}', color: Color(0xFF6366F1)),
    'fmcg': SectorInfo(key: 'fmcg', name: 'FMCG', icon: '\u{1F6D2}', color: Color(0xFFA855F7)),
    'insurance': SectorInfo(key: 'insurance', name: 'Insurance', icon: '\u{1F6E1}\uFE0F', color: Color(0xFF06B6D4)),
    'power': SectorInfo(key: 'power', name: 'Power', icon: '\u{1F4A1}', color: Color(0xFFEAB308)),
    'chemicals': SectorInfo(key: 'chemicals', name: 'Chemicals', icon: '\u{1F9EA}', color: Color(0xFFE11D48)),
    'telecom': SectorInfo(key: 'telecom', name: 'Telecom', icon: '\u{1F4E1}', color: Color(0xFF3B82F6)),
    'other': SectorInfo(key: 'other', name: 'Other', icon: '\u{1F4E6}', color: Color(0xFF94A3B8)),
  };

  static SectorInfo get(String key) => sectors[key] ?? sectors['other']!;

  static List<SectorInfo> get all => sectors.values.toList();
}
