import 'package:intl/intl.dart';

final _idr = NumberFormat('#,##0', 'id_ID');

/// `2450000` → `Rp 2.450.000`.
String formatRupiah(int amount) => 'Rp ${_idr.format(amount)}';
