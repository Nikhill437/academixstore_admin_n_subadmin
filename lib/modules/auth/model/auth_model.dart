class AuthLog {
  final String id;
  final String userId;
  final String userName;
  final String email;
  final String action; // login, logout, failed_login
  final String ipAddress;
  final String deviceInfo;
  final String location;
  final DateTime timestamp;
  final bool isSuccessful;
  final String? failureReason;

  AuthLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.action,
    required this.ipAddress,
    required this.deviceInfo,
    required this.location,
    required this.timestamp,
    required this.isSuccessful,
    this.failureReason,
  });

  factory AuthLog.fromJson(Map<String, dynamic> json) {
    return AuthLog(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      action: json['action'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      deviceInfo: json['deviceInfo'] ?? '',
      location: json['location'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isSuccessful: json['isSuccessful'] ?? false,
      failureReason: json['failureReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'email': email,
      'action': action,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
      'failureReason': failureReason,
    };
  }
}

class AuthSession {
  final String id;
  final String userId;
  final String userName;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String deviceInfo;
  final String ipAddress;
  final bool isActive;

  AuthSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    required this.deviceInfo,
    required this.ipAddress,
    required this.isActive,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      token: json['token'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(days: 7)),
      deviceInfo: json['deviceInfo'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'isActive': isActive,
    };
  }
}
