import 'package:flutter_test/flutter_test.dart';
import 'package:lumasync/core/utils/formatters.dart';
import 'package:lumasync/features/transfer/transfer_limits_text.dart';

void main() {
  test('formatBytes', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1023), '1023 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(150 * 1024 * 1024 * 1024), '150 GB');
  });

  test('formatCount', () {
    expect(formatCount(7), '7');
    expect(formatCount(4950), '4,950');
    expect(formatCount(1234567), '1,234,567');
  });

  test('countOf', () {
    expect(countOf(1, 'video'), '1 video');
    expect(countOf(4950, 'photo'), '4,950 photos');
    expect(countOf(0, 'file'), '0 files');
  });

  test('usage text shows going over the limit plainly', () {
    expect(TransferLimitsText.usageText(37, 100, 'photo'), '37 of 100 photos');
    expect(
      TransferLimitsText.usageText(200, 100, 'photo'),
      '200 photos (limit 100)',
    );
    expect(
      TransferLimitsText.usageText(3, null, 'video'),
      '3 videos (no limit)',
    );
  });
}
