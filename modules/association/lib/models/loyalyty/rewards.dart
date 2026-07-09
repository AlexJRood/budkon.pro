class RewardItem {
  final int id;
  final int program;
  final String code;
  final String name;
  final int costPoints;
  final String rewardType; // voucher_percent | voucher_fixed | perk
  final Map<String, dynamic> payload;
  final bool isActive;
  RewardItem({
    required this.id,
    required this.program,
    required this.code,
    required this.name,
    required this.costPoints,
    required this.rewardType,
    required this.payload,
    required this.isActive,
  });
  factory RewardItem.fromJson(Map<String, dynamic> j) => RewardItem(
    id: j['id'],
    program: (j['program'] is int) ? j['program'] : j['program']['id'],
    code: j['code'],
    name: j['name'],
    costPoints: j['cost_points'],
    rewardType: j['reward_type'],
    payload: (j['payload'] is Map) ? Map<String,dynamic>.from(j['payload']) : {},
    isActive: j['is_active'] ?? true,
  );
}

class Tier {
  final int id;
  final int program;
  final String name;
  final int threshold;
  final Map<String, dynamic> benefits;
  final int order;
  Tier({required this.id, required this.program, required this.name, required this.threshold, required this.benefits, required this.order});
  factory Tier.fromJson(Map<String,dynamic> j) => Tier(
    id: j['id'], program: (j['program'] is int) ? j['program'] : j['program']['id'],
    name: j['name'], threshold: j['threshold'],
    benefits: (j['benefits'] is Map) ? Map<String,dynamic>.from(j['benefits']) : {},
    order: j['order'] ?? 0,
  );
}

class BalanceProgress {
  final int userId;
  final int points;
  final String tier;
  final String? nextTier;
  final int? nextThreshold;
  final double progressPercent;
  BalanceProgress({required this.userId, required this.points, required this.tier, this.nextTier, this.nextThreshold, required this.progressPercent});
  factory BalanceProgress.fromJson(Map<String,dynamic> j) => BalanceProgress(
    userId: j['user_id'], points: j['points'], tier: j['tier'],
    nextTier: j['next_tier'], nextThreshold: j['next_threshold'],
    progressPercent: (j['progress_percent'] as num).toDouble(),
  );
}
