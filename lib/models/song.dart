class Song {
  final String id;
  final String title;
  final String genre;
  final String url;
  int likes;
  int views;
  bool isDownloaded;
  final DateTime addedDate;

  Song({
    required this.id,
    required this.title,
    required this.genre,
    required this.url,
    required this.likes,
    required this.views,
    this.isDownloaded = false,
    required this.addedDate,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      genre: json['genre'] ?? '',
      url: json['url'] ?? '',
      likes: json['likes'] is int
          ? json['likes']
          : int.tryParse(json['likes'].toString()) ?? 0,
      views: json['views'] is int
          ? json['views']
          : int.tryParse(json['views'].toString()) ?? 0,
      addedDate: json['addedDate'] != null
          ? DateTime.tryParse(json['addedDate']) ?? DateTime.now()
          : DateTime.now(),
      isDownloaded: json['isDownloaded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'url': url,
      'likes': likes,
      'views': views,
      'isDownloaded': isDownloaded,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  void incrementLikes() {
    likes++;
  }

  void incrementViews() {
    views++;
  }
}