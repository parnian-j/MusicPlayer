import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final bool isSmall;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    this.onTap,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardWidth = isSmall ? 120.0 : 160.0;
    final cardHeight = isSmall ? 120.0 : 180.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[850],
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          image: playlist.coverImageUrl != null
              ? DecorationImage(
            image: AssetImage(playlist.coverImageUrl!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: Stack(
          children: [
            if (playlist.coverImageUrl != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                playlist.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 12 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }
}