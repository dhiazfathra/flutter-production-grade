import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every locale defines exactly the same keys', () {
    Set<String> keysOf(String path) {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      return json.keys.where((k) => !k.startsWith('@')).toSet();
    }

    final en = keysOf('lib/l10n/app_en.arb');
    final id = keysOf('lib/l10n/app_id.arb');

    expect(id.difference(en), isEmpty, reason: 'keys in id missing from en');
    expect(en.difference(id), isEmpty, reason: 'keys in en missing from id');
  });
}
