// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Flutter Production Grade';

  @override
  String get settings => 'Pengaturan';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Bahasa';

  @override
  String get retry => 'Coba lagi';

  @override
  String get errorNetwork =>
      'Tidak ada koneksi. Periksa jaringan Anda dan coba lagi.';

  @override
  String get errorUnauthorized =>
      'Sesi Anda telah berakhir. Silakan masuk kembali.';

  @override
  String get errorNotFound => 'Kami tidak dapat menemukannya.';

  @override
  String get errorServer =>
      'Server mengalami masalah. Coba lagi sebentar lagi.';

  @override
  String get errorUnknown => 'Terjadi kesalahan.';

  @override
  String get emptyTitle => 'Belum ada apa-apa';

  @override
  String get emptyBody =>
      'Ketika ada sesuatu untuk ditampilkan, itu akan muncul di sini.';
}
