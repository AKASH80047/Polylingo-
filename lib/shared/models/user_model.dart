class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isGuest;
  final String plan;
  final int translationsThisMonth;
  final int translationsMonthlyLimit;
  final double storageUsedGb;
  final double storageTotalGb;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isGuest = false,
    required this.plan,
    required this.translationsThisMonth,
    required this.translationsMonthlyLimit,
    required this.storageUsedGb,
    required this.storageTotalGb,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 'usr_guest',
      name: json['name'] ?? 'Guest User',
      email: json['email'] ?? 'guest@polylingo.ai',
      avatarUrl: json['avatarUrl'],
      isGuest: json['isGuest'] ?? false,
      plan: json['plan'] ?? 'Free Plan',
      translationsThisMonth: json['translationsCount'] ?? json['translationsThisMonth'] ?? 3,
      translationsMonthlyLimit: json['translationsQuota'] ?? json['translationsMonthlyLimit'] ?? 50,
      storageUsedGb: ((json['storageUsedMb'] ?? 1200) / 1024).toDouble(),
      storageTotalGb: ((json['storageQuotaMb'] ?? 5000) / 1024).toDouble(),
    );
  }
}
