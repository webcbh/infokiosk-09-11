/// Understands what the guest (or you) pastes into the setup screen:
///  * a hotel link from  Info Kiosk > Settings > Hotel links   (.../info-kiosk/?mobile=true&hotelId=abc)
///  * or just the website address (https://www.my-hotel.com)
class ParsedLink {
  final String siteOrigin; // https://www.my-hotel.com
  final String? kioskUrl; // full kiosk page url without query, when known
  final String? hotelId;
  const ParsedLink(this.siteOrigin, this.kioskUrl, this.hotelId);
}

ParsedLink? parseLink(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s)) s = 'https://$s';
  final uri = Uri.tryParse(s);
  if (uri == null || uri.host.isEmpty || !(uri.scheme == 'https' || uri.scheme == 'http')) return null;
  final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  final hotel = uri.queryParameters['hotelId'];
  final path = uri.path;
  final hasPage = path.isNotEmpty && path != '/';
  final kiosk = hasPage ? '$origin$path' : null;
  return ParsedLink(origin, kiosk, (hotel != null && hotel.isNotEmpty) ? hotel : null);
}

/// Possible REST roots, most likely first. WordPress may live in the site root or in a sub-folder
/// (https://host/hotel/...), so every path prefix of a pasted link is tried too.
List<String> restCandidates(ParsedLink p, String input) {
  final out = <String>[];
  void add(String base) {
    final c = '$base/wp-json/infokiosk/v1';
    if (!out.contains(c)) out.add(c);
  }

  add(p.siteOrigin);
  final uri = Uri.tryParse(input.trim().contains('://') ? input.trim() : 'https://${input.trim()}');
  final segs = (uri?.pathSegments ?? const <String>[]).where((e) => e.isNotEmpty).toList();
  var acc = p.siteOrigin;
  for (final seg in segs) {
    acc = '$acc/$seg';
    add(acc);
  }
  return out;
}
