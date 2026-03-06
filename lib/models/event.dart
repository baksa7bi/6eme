import 'cafe.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String imageUrl;
  final String? videoUrl;
  final String location;
  final Cafe? cafe;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    this.videoUrl,
    required this.location,
    this.cafe,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      imageUrl: json['image_url'] ?? '',
      videoUrl: json['video_url'],
      location: json['location'] ?? '',
      cafe: json['cafe'] != null ? Cafe.fromJson(json['cafe']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'image_url': imageUrl,
      'video_url': videoUrl,
      'location': location,
    };
  }
}
