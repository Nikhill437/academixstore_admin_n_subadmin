class DashboardStats {
  final int totalUsers;
  final int totalStudents;
  final int activeUsers;
  final int totalRevenue;
  final int totalOrders;
  final int totalProducts;
  final double userGrowthRate;
  final double revenueGrowthRate;
  final double orderGrowthRate;
  final DateTime lastUpdated;

  DashboardStats({
    required this.totalUsers,
    required this.totalStudents,
    required this.activeUsers,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalProducts,
    required this.userGrowthRate,
    required this.revenueGrowthRate,
    required this.orderGrowthRate,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      userGrowthRate: (json['userGrowthRate'] ?? 0.0).toDouble(),
      revenueGrowthRate: (json['revenueGrowthRate'] ?? 0.0).toDouble(),
      orderGrowthRate: (json['orderGrowthRate'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalStudents': totalStudents,
      'activeUsers': activeUsers,
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'totalProducts': totalProducts,
      'userGrowthRate': userGrowthRate,
      'revenueGrowthRate': revenueGrowthRate,
      'orderGrowthRate': orderGrowthRate,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class RecentActivity {
  final String id;
  final String title;
  final String description;
  final String type; // user_action, system_event, order_update
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String status; // info, success, warning, error

  RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.status,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'info',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: json['status'] ?? 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
