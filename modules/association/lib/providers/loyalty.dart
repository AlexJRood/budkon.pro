
import 'package:association/models/loyalyty/rewards.dart';
import 'package:association/screens/loyalty/loyalty_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final rewardsProv = FutureProvider.family<List<RewardItem>, ({String baseUrl, int programId})>((ref, a) async {
  final api = ref.read(loyaltyApiProvider(a.baseUrl));
  return api.listRewards(programId: a.programId);
});

final balanceProv = FutureProvider.family<BalanceProgress, ({String baseUrl, int programId})>((ref, a) async {
  final api = ref.read(loyaltyApiProvider(a.baseUrl));
  return api.getBalance(programId: a.programId);
});
