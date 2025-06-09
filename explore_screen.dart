import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../widgets/playlist_card.dart';

class ExploreScreen extends StatefulWidget {
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Song> allSongs = []; // باید از API بارگذاری بشه یا MockData
  List<Song> popularSongs = [];
  List<Song> mostViewedSongs = [];
  List<Playlist> genrePlaylists = [];

  List<Song> searchResults = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongsAndPlaylists();
  }

  void _loadSongsAndPlaylists() {
    //  برای نمونه
    allSongs = [
      Song(id: '1', title: 'Song A', genre: 'Pop', addedDate: DateTime.now(), likes: 20, views: 50),
      Song(id: '2', title: 'Song B', genre: 'Rock', addedDate: DateTime.now().subtract(Duration(days: 1)), likes: 50, views: 200),
      Song(id: '3', title: 'Song C', genre: 'Jazz', addedDate: DateTime.now().subtract(Duration(days: 2)), likes: 5, views: 15),
      Song(id: '4', title: 'Song D', genre: 'Pop', addedDate: DateTime.now(), likes: 10, views: 30),
      Song(id: '5', title: 'Song E', genre: 'Jazz', addedDate: DateTime.now(), likes: 40, views: 100),

    ];

    popularSongs = List.from(allSongs);
    popularSongs.sort((a, b) => b.likes.compareTo(a.likes));
    popularSongs = popularSongs.take(10).toList();

    mostViewedSongs = List.from(allSongs);
    mostViewedSongs.sort((a, b) => b.views.compareTo(a.views));
    mostViewedSongs = mostViewedSongs.take(10).toList();

    _generateGenrePlaylists();
  }

  void _generateGenrePlaylists() {
    final genres = allSongs.map((s) => s.genre).toSet();

    genrePlaylists = genres.map((genre) {
      final songs = allSongs.where((s) => s.genre == genre).toList();
      return Playlist(
        id: genre.toLowerCase(),
        name: genre,
        songs: songs,
        coverImageUrl: _getGenreImage(genre),
      );
    }).toList();
  }

  String _getGenreImage(String genre) {
    switch (genre.toLowerCase()) {
      case 'pop':
        return 'assets/images/pop.jpg';
      case 'rock':
        return 'assets/images/rock.jpg';
      case 'jazz':
        return 'assets/images/jazz.jpg';
      default:
        return 'assets/images/default_genre.jpg';
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        searchResults.clear();
      } else {
        searchResults = allSongs
            .where((s) => s.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _downloadSong(Song song) {
    setState(() {
      song.isDownloaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded ${song.title}')),
    );
  }

  void _addToMySongs(Song song) {
    // باید به لیست مای سانگز اضافه بشه (بک‌اند)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${song.title} added to My Songs')),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        title: Text('Explore'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchResults.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: searchResults.map((song) => ListTile(
                    title: Text(song.title, style: TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!song.isDownloaded)
                          IconButton(
                            icon: Icon(Icons.download, color: Colors.cyanAccent),
                            onPressed: () => _downloadSong(song),
                          ),
                        IconButton(
                          icon: Icon(Icons.add, color: Colors.cyanAccent),
                          onPressed: () => _addToMySongs(song),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              )
            else ...[
              _buildSectionTitle('Top 10 Popular Songs'),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularSongs.length,
                  itemBuilder: (ctx, i) => PlaylistCard(
                    playlist: Playlist(
                      id: 'popular_$i',
                      name: popularSongs[i].title,
                      songs: [popularSongs[i]],
                      coverImageUrl: 'assets/images/popular.jpg',
                    ),
                    isSmall: true,
                    onTap: () {
                      // TODO: نمایش لیست آهنگ های پرطرفدار
                    },
                  ),
                ),
              ),

              _buildSectionTitle('Top 10 Most Viewed Songs'),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mostViewedSongs.length,
                  itemBuilder: (ctx, i) => PlaylistCard(
                    playlist: Playlist(
                      id: 'mostviewed_$i',
                      name: mostViewedSongs[i].title,
                      songs: [mostViewedSongs[i]],
                      coverImageUrl: 'assets/images/viewed.jpg',
                    ),
                    isSmall: true,
                    onTap: () {
                      // TODO: نمایش لیست آهنگ های پر بازدید
                    },
                  ),
                ),
              ),

              _buildSectionTitle('Genres'),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: genrePlaylists.length,
                  itemBuilder: (ctx, i) {
                    final pl = genrePlaylists[i];
                    return PlaylistCard(
                      playlist: pl,
                      onTap: () {
                        // نمایش پلی‌لیست ژانر
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}