// lib/models/playlist.dart
import 'song.dart';

class Playlist {
  late final String id;
  final String name;
  List<Song> songs;
  final String coverImageUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.coverImageUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coverImageUrl': coverImageUrl,
    'songs': songs.map((s) => s.toJson()).toList(),
  };
}