/// Result of generating a Cliq linking code
class CliqLinkingResult {
  final String code;
  final int challengeNumber;
  final DateTime expiresAt;

  const CliqLinkingResult({
    required this.code,
    required this.challengeNumber,
    required this.expiresAt,
  });

  factory CliqLinkingResult.fromJson(Map<String, dynamic> json) {
    return CliqLinkingResult(
      code: json['code'] as String,
      challengeNumber: json['challengeNumber'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
