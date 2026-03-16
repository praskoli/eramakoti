class TempleConfig {
  final String id;
  final String name;
  final String city;
  final String address;
  final String upiId;
  final String payeeName;
  final String? logoUrl;
  final bool active;
  final String? themeColor;
  final String? secondaryColor;
  final String? bannerUrl;
  final bool supportEnabled;
  final bool leaderboardEnabled;
  final String? homeWelcomeText;

  const TempleConfig({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.upiId,
    required this.payeeName,
    required this.logoUrl,
    required this.active,
    required this.themeColor,
    required this.secondaryColor,
    required this.bannerUrl,
    required this.supportEnabled,
    required this.leaderboardEnabled,
    required this.homeWelcomeText,
  });

  factory TempleConfig.fromMap(Map<String, dynamic> map) {
    return TempleConfig(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      upiId: (map['upiId'] ?? '') as String,
      payeeName: (map['payeeName'] ?? '') as String,
      logoUrl: map['logoUrl'] as String?,
      active: (map['active'] ?? false) as bool,
      themeColor: map['themeColor'] as String?,
      secondaryColor: map['secondaryColor'] as String?,
      bannerUrl: map['bannerUrl'] as String?,
      supportEnabled: (map['supportEnabled'] ?? true) as bool,
      leaderboardEnabled: (map['leaderboardEnabled'] ?? true) as bool,
      homeWelcomeText: map['homeWelcomeText'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'upiId': upiId,
      'payeeName': payeeName,
      'logoUrl': logoUrl,
      'active': active,
      'themeColor': themeColor,
      'secondaryColor': secondaryColor,
      'bannerUrl': bannerUrl,
      'supportEnabled': supportEnabled,
      'leaderboardEnabled': leaderboardEnabled,
      'homeWelcomeText': homeWelcomeText,
    };
  }

  bool get hasValidSupportConfig =>
      upiId.trim().isNotEmpty && payeeName.trim().isNotEmpty;
}
