import 'package:flutter_test/flutter_test.dart';
import 'package:mypulse/models/signal_template.dart';

void main() {
  test('exactly the 6 predefined signals exist, no more, no less', () {
    expect(kSignalTemplates.length, 6);
    expect(kSignalTemplates.map((t) => t.id).toSet().length, 6, reason: 'ids must be unique');
  });
}
