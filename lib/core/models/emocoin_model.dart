class EmoCoinModel {
  final String id;
  final String userId;
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final DateTime? lastDailyClaim;
  final int dailyStreak;
  final List<CoinTransaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmoCoinModel({
    required this.id,
    required this.userId,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    this.lastDailyClaim,
    this.dailyStreak = 0,
    this.transactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmoCoinModel.fromJson(Map<String, dynamic> json) {
    return EmoCoinModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalRedeemed: json['total_redeemed'] ?? 0,
      lastDailyClaim: json['last_daily_claim'] != null
          ? DateTime.parse(json['last_daily_claim'])
          : null,
      dailyStreak: json['daily_streak'] ?? 0,
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((t) => CoinTransaction.fromJson(t))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'balance': balance,
    'total_earned': totalEarned,
    'total_redeemed': totalRedeemed,
    'last_daily_claim': lastDailyClaim?.toIso8601String(),
    'daily_streak': dailyStreak,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  bool get canClaimDaily {
    if (lastDailyClaim == null) return true;
    final now = DateTime.now();
    final last = lastDailyClaim!;
    return now.year > last.year ||
        now.month > last.month ||
        now.day > last.day;
  }

  double get rupeeValue => balance * 1.0;
  bool get canExchangeForCrypto => balance >= 500;
  int get cryptoExchangeAmount => (balance / 500).floor() * 500;
}

class CoinTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final int amount;
  final String description;
  final String? referenceId;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.earn,
      ),
      amount: json['amount'] ?? 0,
      description: json['description'] ?? '',
      referenceId: json['reference_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'amount': amount,
    'description': description,
    'reference_id': referenceId,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isEarn => type == TransactionType.earn;
  bool get isRedeem => type == TransactionType.redeem;
}

enum TransactionType { earn, redeem, exchange, bonus, referral }