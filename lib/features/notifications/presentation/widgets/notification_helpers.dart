import 'package:flutter/material.dart';

Color categoryColor(String category) {
  return switch (category) {
    'finance' || 'dues' => const Color(0xFF0B7A35),
    'aspiration' => const Color(0xFF5134D4),
    'letter' => const Color(0xFFC27803),
    'announcement' => const Color(0xFF0967D8),
    'membership' => const Color(0xFF0967D8),
    _ => const Color(0xFF0967D8),
  };
}

String categoryLabel(String category) {
  return switch (category) {
    'finance' => 'Keuangan',
    'dues' => 'Keuangan',
    'aspiration' => 'Aspirasi',
    'letter' => 'Surat',
    'announcement' => 'Pengumuman',
    'membership' => 'Keanggotaan',
    'system' => 'Sistem',
    _ => 'Notifikasi',
  };
}
