class Song {
  final String id;
  final String title;
  final String genre;
  final DateTime addedDate;
  int likes;
  int views;
  bool isDownloaded;
  bool liked;

  Song({
    required this.id,
    required this.title,
    required this.genre,
    required this.addedDate,
    this.likes = 0,
    this.views = 0,
    this.isDownloaded = false,
    this.liked = false,
  });
}