import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.loadNotifications();
      notifProvider.clearUnread();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notifications = notifProvider.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final data = notif['data'] as Map<String, dynamic>;
              final createdAt = DateTime.parse(notif['created_at']);
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                ),
                title: Text(data['title'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
