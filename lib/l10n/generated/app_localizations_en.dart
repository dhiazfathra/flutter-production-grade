// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Production Grade';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get retry => 'Retry';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorUnauthorized => 'Your session expired. Sign in again.';

  @override
  String get errorNotFound => 'We couldn\'t find that.';

  @override
  String get errorServer => 'The server had a problem. Try again shortly.';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyBody =>
      'When there is something to show, it will appear here.';
}
