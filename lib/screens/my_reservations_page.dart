import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation.dart';
import '../providers/auth_provider.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<ReservationProvider>().fetchReservations(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isManager = auth.user?.isManager == true || auth.user?.isAdmin == true;
    final reservations = reservationProvider.reservations;

    final tableReservations = reservations.where((r) => r.type == 'table').toList();
    final anniversaryReservations = reservations.where((r) => r.type == 'birthday' || r.type == 'anniversaire').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isManager ? 'Gestion Réservations' : 'Mes Réservations'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Tables', icon: Icon(Icons.restaurant)),
              Tab(text: 'Anniversaires', icon: Icon(Icons.cake)),
            ],
          ),
        ),
        body: Column(
          children: [
            if (isManager) 
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _filterChip('all', 'Toutes'),
                    _filterChip('active', 'Actives'),
                    _filterChip('history', 'Historique'),
                    _filterChip('cancelled', 'Annulés'),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildReservationList(context, tableReservations, isManager, reservationProvider.isLoading),
                  _buildReservationList(context, anniversaryReservations, isManager, reservationProvider.isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList(BuildContext context, List<Reservation> list, bool isManager, bool isLoading) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return _buildEmptyState();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final res = list[index];
        return _buildReservationCard(context, res, isManager);
      },
    );
  }

  Widget _filterChip(String status, String label) {
    bool isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedStatus = status);
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune réservation trouvée',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation res, bool isManager) {
    final isBirthday = res.type == 'birthday';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isBirthday ? Colors.pink[50] : Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            isBirthday ? Icons.cake : Icons.restaurant,
            color: isBirthday ? Colors.pink : Theme.of(context).primaryColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(res.cafeName, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isBirthday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.pink[100], borderRadius: BorderRadius.circular(4)),
                child: const Text('ANNIVERSAIRE', style: TextStyle(color: Colors.pink, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isManager) ...[
               Text('Client: ${res.clientName ?? 'Inconnu'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
               if (res.clientPhone != null) 
                 GestureDetector(
                   onTap: () async {
                     final Uri url = Uri.parse('tel:${res.clientPhone}');
                     if (await canLaunchUrl(url)) {
                       await launchUrl(url);
                     }
                   },
                   child: Text('📞 ${res.clientPhone}', style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
                 ),
            ],
            Text('Table pour ${res.numberOfPeople} personnes'),
            const SizedBox(height: 4),
            Text('📅 ${DateFormat('dd/MM/yyyy').format(res.dateTime)} à ${DateFormat('HH:mm').format(res.dateTime)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _statusBadge(res.status),
              ],
            ),
          ],
        ),
        onTap: () => _showReservationDetails(context, res, isManager),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showReservationDetails(BuildContext context, Reservation res, bool isManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(res.cafeName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.people, 'Personnes', '${res.numberOfPeople}'),
            _detailRow(Icons.calendar_today, 'Date', DateFormat('dd/MM/yyyy').format(res.dateTime)),
            _detailRow(Icons.access_time, 'Heure', DateFormat('HH:mm').format(res.dateTime)),
            _detailRow(Icons.info_outline, 'Statut', res.status.toUpperCase()),
            const Divider(),
            if (res.clientName != null) _detailRow(Icons.person, 'Client', res.clientName!),
            if (res.clientPhone != null) _detailRow(Icons.phone, 'Téléphone', res.clientPhone!, 
              onTap: () async {
                final Uri url = Uri.parse('tel:${res.clientPhone}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }),
            if (res.specialRequests != null && res.specialRequests!.isNotEmpty) ...[
              const Divider(),
              const Text('Demandes spéciales :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(res.specialRequests!),
            ],
          ],
        ),
        actions: [
          if (isManager && res.status == 'pending') ...[
            TextButton(
              onPressed: () async {
                final success = await context.read<ReservationProvider>().updateStatus(
                  int.parse(res.id), 
                  'cancelled',
                  currentFilterStatus: _selectedStatus == 'all' ? null : _selectedStatus,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation annulée'), backgroundColor: Colors.red));
                }
              },
              child: const Text('ANNULER', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<ReservationProvider>().updateStatus(
                  int.parse(res.id), 
                  'confirmed',
                  currentFilterStatus: _selectedStatus == 'all' ? null : _selectedStatus,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation confirmée'), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('CONFIRMER'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(color: Colors.grey)),
            Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: onTap != null ? Colors.blue : null))),
            if (onTap != null) const Icon(Icons.phone, size: 14, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
