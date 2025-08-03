import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;
  final String coverImageUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.coverImageUrl,
  });
}