import 'package:flutter/material.dart';
import '../model/auth_model.dart';
import '../../../common_widgets/common_data_table.dart';
import '../../../common_widgets/shared_sidebar.dart';

class AuthLogsTableView extends StatefulWidget {
  const AuthLogsTableView({super.key});

  @override
  State<AuthLogsTableView> createState() => _AuthLogsTableViewState();
}

class _AuthLogsTableViewState extends State<AuthLogsTableView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AuthLog> _authLogs = [];
  List<AuthLog> _filteredAuthLogs = [];
  List<AuthSession> _activeSessions = [];
  List<AuthSession> _filteredSessions = [];
  int _selectedSidebarIndex = 4; // Auth Logs is the fifth item

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAuthData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAuthData() {
    // Mock auth logs data
    _authLogs = [
      AuthLog(
        id: '1',
        userId: 'user_001',
        userName: 'John Doe',
        email: 'john.doe@example.com',
        action: 'login',
        ipAddress: '192.168.1.100',
        deviceInfo: 'Chrome 120.0.0 on Windows 11',
        location: 'New York, US',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isSuccessful: true,
      ),
      AuthLog(
        id: '2',
        userId: 'user_002',
        userName: 'Jane Smith',
        email: 'jane.smith@example.com',
        action: 'failed_login',
        ipAddress: '203.0.113.45',
        deviceInfo: 'Safari 17.0 on macOS',
        location: 'London, UK',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
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
        deviceInfo: 'Firefox 121.0 on Linux',
        location: 'Berlin, DE',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isSuccessful: true,
      ),
      AuthLog(
        id: '4',
        userId: 'user_001',
        userName: 'John Doe',
        email: 'john.doe@example.com',
        action: 'login',
        ipAddress: '192.168.1.100',
        deviceInfo: 'Mobile Chrome on Android',
        location: 'New York, US',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isSuccessful: true,
      ),
      AuthLog(
        id: '5',
        userId: 'user_004',
        userName: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        action: 'failed_login',
        ipAddress: '198.51.100.23',
        deviceInfo: 'Edge 120.0 on Windows 10',
        location: 'Toronto, CA',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isSuccessful: false,
        failureReason: 'Account locked',
      ),
    ];

    // Mock active sessions data
    _activeSessions = [
      AuthSession(
        id: 'session_001',
        userId: 'user_001',
        userName: 'John Doe',
        token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        deviceInfo: 'Chrome 120.0.0 on Windows 11',
        ipAddress: '192.168.1.100',
        isActive: true,
      ),
      AuthSession(
        id: 'session_002',
        userId: 'user_002',
        userName: 'Jane Smith',
        token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 6)),
        deviceInfo: 'Safari 17.0 on macOS',
        ipAddress: '203.0.113.45',
        isActive: true,
      ),
      AuthSession(
        id: 'session_003',
        userId: 'user_001',
        userName: 'John Doe',
        token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        deviceInfo: 'Mobile Chrome on Android',
        ipAddress: '192.168.1.101',
        isActive: true,
      ),
    ];

    _filteredAuthLogs = List.from(_authLogs);
    _filteredSessions = List.from(_activeSessions);
    setState(() {});
  }

  void _onSearchLogs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAuthLogs = List.from(_authLogs);
      } else {
        _filteredAuthLogs = _authLogs
            .where(
              (log) =>
                  log.userName.toLowerCase().contains(query.toLowerCase()) ||
                  log.email.toLowerCase().contains(query.toLowerCase()) ||
                  log.action.toLowerCase().contains(query.toLowerCase()) ||
                  log.ipAddress.toLowerCase().contains(query.toLowerCase()) ||
                  log.location.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onSearchSessions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSessions = List.from(_activeSessions);
      } else {
        _filteredSessions = _activeSessions
            .where(
              (session) =>
                  session.userName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  session.deviceInfo.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  session.ipAddress.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onViewLogDetails(AuthLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Log Details'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', log.id),
              _buildDetailRow('User', log.userName),
              _buildDetailRow('Email', log.email),
              _buildDetailRow('Action', log.action.toUpperCase()),
              _buildDetailRow('IP Address', log.ipAddress),
              _buildDetailRow('Device', log.deviceInfo),
              _buildDetailRow('Location', log.location),
              _buildDetailRow('Timestamp', _formatDateTime(log.timestamp)),
              _buildDetailRow(
                'Status',
                log.isSuccessful ? 'SUCCESS' : 'FAILED',
              ),
              if (!log.isSuccessful && log.failureReason != null)
                _buildDetailRow('Failure Reason', log.failureReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onRevokeSession(AuthSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Session'),
        content: Text(
          'Are you sure you want to revoke the session for ${session.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement session revocation logic here
              Navigator.pop(context);
              _showSuccessSnackBar('Session revoked successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
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

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.blue;
      case 'failed_login':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Authentication Logs'),
                Tab(text: 'Active Sessions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Authentication Logs Tab
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: CommonDataTable<AuthLog>(
                    title: 'Authentication Logs',
                    data: _filteredAuthLogs,
                    searchHint: 'Search logs by user, action, IP, location...',
                    onSearch: _onSearchLogs,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('IP Address')),
                      DataColumn(label: Text('Device')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rowBuilder: (logs) => logs
                        .map(
                          (log) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: _getActionColor(
                                        log.action,
                                      ),
                                      child: Icon(
                                        _getActionIcon(log.action),
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          log.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          log.email,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getActionColor(
                                      log.action,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getActionColor(
                                        log.action,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    log.action.toUpperCase(),
                                    style: TextStyle(
                                      color: _getActionColor(log.action),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(log.ipAddress)),
                              DataCell(
                                Tooltip(
                                  message: log.deviceInfo,
                                  child: SizedBox(
                                    width: 120,
                                    child: Text(
                                      log.deviceInfo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(log.location)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getTimeAgo(log.timestamp),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: log.isSuccessful
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: log.isSuccessful
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    log.isSuccessful ? 'SUCCESS' : 'FAILED',
                                    style: TextStyle(
                                      color: log.isSuccessful
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                TableActionButton(
                                  icon: Icons.visibility,
                                  color: Colors.blue,
                                  tooltip: 'View Details',
                                  onPressed: () => _onViewLogDetails(log),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Active Sessions Tab
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: CommonDataTable<AuthSession>(
                    title: 'Active Sessions',
                    data: _filteredSessions,
                    searchHint: 'Search sessions by user, device, IP...',
                    onSearch: _onSearchSessions,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Device')),
                      DataColumn(label: Text('IP Address')),
                      DataColumn(label: Text('Created')),
                      DataColumn(label: Text('Expires')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rowBuilder: (sessions) => sessions
                        .map(
                          (session) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.green,
                                      child: Text(
                                        session.userName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          session.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${session.userId}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Tooltip(
                                  message: session.deviceInfo,
                                  child: SizedBox(
                                    width: 150,
                                    child: Text(
                                      session.deviceInfo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(session.ipAddress)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getTimeAgo(session.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(session.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatDateTime(session.expiresAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                TableActionButton(
                                  icon: Icons.power_settings_new,
                                  color: Colors.red,
                                  tooltip: 'Revoke Session',
                                  onPressed: () => _onRevokeSession(session),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
