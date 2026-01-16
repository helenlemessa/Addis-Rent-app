class FavoriteModel {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.createdAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteModel(
      id: id,
      userId: map['userId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}