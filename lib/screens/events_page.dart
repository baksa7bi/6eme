import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'reservation_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements à Venir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Event>>(
        future: ApiService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('Aucun événement prévu pour le moment.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2D), // Deep dark blue background
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Part
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                          child: (event.imageUrl.startsWith('http') || event.imageUrl.startsWith('https')) 
                            ? CachedNetworkImage(
                                imageUrl: event.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[900]),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
                              )
                            : Image.asset(
                                event.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[900], 
                                  child: const Icon(Icons.broken_image, color: Colors.white),
                                ),
                              ),
                        ),
                      ),
                      // Text Part with yellow border
                      Expanded(
                        flex: 6,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFFFB606), width: 3),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'LE ${DateFormat('dd MMMM', 'fr_FR').format(event.date).toUpperCase()}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFB606), // Yellow accent
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'À ${event.location.toUpperCase()}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFB606),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 32), // Space for absolute positioned button
                                ],
                              ),
                              // Button at bottom right
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () {
                                    if (event.cafe != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReservationPage(cafe: event.cafe!),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Impossible de vérifier avec le café pour le moment.')),
                                      );
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC33),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: const Text(
                                      'Réserver Votre Table',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
