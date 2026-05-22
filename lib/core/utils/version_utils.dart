/// Semantic version comparison utilities.
class VersionUtils {
  /// Parse semantic version string into integer list
  static List<int> parse(String v) {
    return v.split('.').map((p) {
      final n = int.tryParse(p.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
      return n;
    }).toList();
  }

  /// Compare two semantic versions.
  /// Returns -1 if a < b, 0 if equal, 1 if a > b
  static int compare(String a, String b) {
    final pa = parse(a);
    final pb = parse(b);
    final maxLen = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < maxLen; i++) {
      final va = (i < pa.length) ? pa[i] : 0;
      final vb = (i < pb.length) ? pb[i] : 0;
      if (va < vb) return -1;
      if (va > vb) return 1;
    }
    return 0;
  }
}
