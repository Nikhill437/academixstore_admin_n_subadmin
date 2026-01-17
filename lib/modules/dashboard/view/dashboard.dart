import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/dashboard_model.dart';
import '../../users/model/user.dart';
import '../../auth/model/auth_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../common_widgets/shared_sidebar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSidebarIndex = 0; // Dashboard is the first item
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SharedSidebar(
            selectedIndex: _selectedSidebarIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedSidebarIndex = index;
              });
            },
            onLogout: () => _authController.logout(),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  // Top App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            'JD',
                            style: TextStyle(
                              color: Colors.indigo.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashboard Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard(
                                'Total Users',
                                '12,567',
                                Icons.people_rounded,
                                Colors.blue,
                                '+12.5%',
                              ),
                              _buildStatCard(
                                'Revenue',
                                '\$45,890',
                                Icons.attach_money_rounded,
                                Colors.green,
                                '+8.2%',
                              ),
                              _buildStatCard(
                                'Orders',
                                '3,421',
                                Icons.shopping_cart_rounded,
                                Colors.orange,
                                '+23.1%',
                              ),
                              _buildStatCard(
                                'Products',
                                '892',
                                Icons.inventory_rounded,
                                Colors.purple,
                                '+5.4%',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Dashboard Tables Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recent Users Table
                              Expanded(child: _buildRecentUsersTable()),
                              const SizedBox(width: 24),
                              // Recent Activity Table
                              Expanded(child: _buildRecentActivityTable()),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Recent Authentication Logs Table
                          _buildRecentAuthLogsTable(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsersTable() {
    // Mock recent users data
    final List<User> recentUsers = [
      User(
        id: '1',
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        mobile: '+1234567890',
        role: 'super_admin',
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      User(
        id: '2',
        fullName: 'Jane Smith',
        email: 'jane.smith@example.com',
        mobile: '+1234567891',
        role: 'student',
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      User(
        id: '3',
        fullName: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        mobile: '+1234567892',
        role: 'college_admin',
        isActive: true,
        isVerified: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full users table
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: recentUsers.length,
              itemBuilder: (context, index) {
                final user = recentUsers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user.role),
                    child: Text(
                      user.fullName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.roleDisplayText.toUpperCase(),
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTable() {
    final List<RecentActivity> recentActivities = [
      RecentActivity(
        id: '1',
        title: 'New user registered',
        description: 'John Doe created a new account',
        type: 'user_action',
        userId: 'user_001',
        userName: 'John Doe',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'success',
      ),
      RecentActivity(
        id: '2',
        title: 'Student enrolled',
        description: 'Alice Johnson enrolled in Computer Science',
        type: 'system_event',
        userId: 'student_001',
        userName: 'Alice Johnson',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'info',
      ),
      RecentActivity(
        id: '3',
        title: 'Session expired',
        description: 'User session for Mike Johnson expired',
        type: 'system_event',
        userId: 'user_003',
        userName: 'Mike Johnson',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'warning',
      ),
    ];

    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full activity logs
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getActivityColor(activity.status),
                    child: Icon(
                      _getActivityIcon(activity.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.description),
                      Text(
                        _getTimeAgo(activity.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAuthLogsTable() {
    final List<AuthLog> recentAuthLogs = [
      AuthLog(
        id: '1',
        userId: 'user_001',
        userName: 'John Doe',
        email: 'john.doe@example.com',
        action: 'login',
        ipAddress: '192.168.1.100',
        deviceInfo: 'Chrome on Windows',
        location: 'New York, US',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isSuccessful: true,
      ),
      AuthLog(
        id: '2',
        userId: 'user_002',
        userName: 'Jane Smith',
        email: 'jane.smith@example.com',
        action: 'failed_login',
        ipAddress: '203.0.113.45',
        deviceInfo: 'Safari on macOS',
        location: 'London, UK',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isSuccessful: false,
        failureReason: 'Invalid password',
      ),
      AuthLog(
        id: '3',
        userId: 'user_003',
        userName: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        action: 'logout',
        ipAddress: '192.168.1.105',
        deviceInfo: 'Firefox on Linux',
        location: 'Berlin, DE',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isSuccessful: true,
      ),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Authentication Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full auth logs
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: recentAuthLogs.length,
              itemBuilder: (context, index) {
                final log = recentAuthLogs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: log.isSuccessful
                        ? Colors.green
                        : Colors.red,
                    child: Icon(
                      _getAuthIcon(log.action),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '${log.userName} - ${log.action.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${log.ipAddress} • ${log.location}'),
                      Text(
                        _getTimeAgo(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: log.isSuccessful
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.isSuccessful ? 'SUCCESS' : 'FAILED',
                      style: TextStyle(
                        color: log.isSuccessful ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return Colors.purple;
      case 'college_admin':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'user':
      default:
        return Colors.orange;
    }
  }

  Color _getActivityColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user_action':
        return Icons.person;
      case 'system_event':
        return Icons.settings;
      case 'order_update':
        return Icons.shopping_cart;
      default:
        return Icons.info;
    }
  }

  IconData _getAuthIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'failed_login':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
