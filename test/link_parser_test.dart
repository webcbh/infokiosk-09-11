import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guide_app/link_parser.dart';

void main() {
  test('plain website', () {
    final p = parseLink('www.my-hotel.com')!;
    expect(p.siteOrigin, 'https://www.my-hotel.com');
    expect(p.hotelId, isNull);
  });
  test('hotel link', () {
    final p = parseLink('https://my-hotel.com/info-kiosk/?mobile=true&hotelId=h3')!;
    expect(p.siteOrigin, 'https://my-hotel.com');
    expect(p.kioskUrl, 'https://my-hotel.com/info-kiosk/');
    expect(p.hotelId, 'h3');
  });
  test('sub-folder install is tried', () {
    const input = 'https://host.com/client/info-kiosk/?hotelId=a';
    final c = restCandidates(parseLink(input)!, input);
    expect(c.first, 'https://host.com/wp-json/infokiosk/v1');
    expect(c, contains('https://host.com/client/wp-json/infokiosk/v1'));
  });
  test('garbage is rejected', () {
    expect(parseLink(''), isNull);
    expect(parseLink('ftp://x.com'), isNull);
  });
}
