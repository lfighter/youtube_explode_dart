// Offline: the relative upload-date text YouTube renders, parsed without a
// network round trip. Every other test here asks YouTube; this one pins down
// the parser those answers go through.
import 'package:test/test.dart';
import 'package:youtube_explode_dart/src/extensions/helpers_extension.dart';

void main() {
  void expectAgo(String text, Duration age) {
    final parsed = text.toDateTime();
    expect(parsed, isNotNull, reason: '"$text" names an age');
    final expected = DateTime.now().subtract(age);
    expect(
      parsed!.difference(expected).abs(),
      lessThan(const Duration(minutes: 1)),
      reason: '"$text" is $age ago',
    );
  }

  group('an age is read', () {
    test('written out', () {
      expectAgo('45 seconds ago', const Duration(seconds: 45));
      expectAgo('1 minute ago', const Duration(minutes: 1));
      expectAgo('3 days ago', const Duration(days: 3));
      expectAgo('2 weeks ago', const Duration(days: 14));
      expectAgo('1 month ago', const Duration(days: 30));
      expectAgo('2 years ago', const Duration(days: 730));
    });

    test('compact', () {
      expectAgo('16h ago', const Duration(hours: 16));
      expectAgo('5m ago', const Duration(minutes: 5));
      expectAgo('1mo ago', const Duration(days: 30));
      expectAgo('3y ago', const Duration(days: 1095));
    });

    test('after a word saying what happened then', () {
      // The compact form with a prefix is three words, so a parser that only
      // dropped the first of four fed "Streamed" to int.parse — and threw out
      // of every search and channel listing holding a past live stream.
      expectAgo('Streamed 16h ago', const Duration(hours: 16));
      expectAgo('Streamed 2 days ago', const Duration(days: 2));
      expectAgo('Streamed live 5 hours ago', const Duration(hours: 5));
      expectAgo('Premiered 3 weeks ago', const Duration(days: 21));
    });
  });

  group('text with no age is no date, never an exception', () {
    // Upstream issue #309: PREMIERE and Streamed items threw FormatException.
    for (final text in [
      'PREMIERE',
      'LIVE',
      'Streamed live on Jan 5, 2020',
      'Scheduled for 10/16/26, 8:00 PM',
      'Premieres in 3 hours',
      '3 fortnights ago',
      '99999999999999999999 days ago',
      '',
      '   ',
    ]) {
      test('"$text"', () => expect(text.toDateTime(), isNull));
    }

    test('null', () => expect((null as String?).toDateTime(), isNull));
  });
}
