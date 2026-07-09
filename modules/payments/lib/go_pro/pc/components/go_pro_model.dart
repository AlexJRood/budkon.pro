class SubscriptionPackage {
  final String name;
  final String user;
  final String userCategory; // Changed to String
  final String discountPrice;
  final String price;
  final String description;
  final String group;
  final bool started;
  final String validityTimeType;
  final int validity;
  final bool forAllUsers;
  final DateTime dateCreated;
  final DateTime lastUpdated;
  final Map <dynamic,dynamic> features;

  SubscriptionPackage({
    required this.name,
    required this.user,
    required this.userCategory,
    required this.discountPrice,
    required this.price,
    required this.description,
    required this.group,
    required this.started,
    required this.validityTimeType,
    required this.validity,
    required this.forAllUsers,
    required this.dateCreated,
    required this.lastUpdated,
    required this.features,
  });
}
