class Song {
  final String id;
  final String title;
  final String genre;
  final DateTime addedDate;
  final int likes;
  final int views;
  bool isDownloaded;

  Song({
    required this.id,
    required this.title,
    required this.genre,
    required this.addedDate,
    required this.likes,
    required this.views,
    this.isDownloaded = false,
  });
}