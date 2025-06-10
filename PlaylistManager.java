/*import java.util.*;

public class PlaylistManager {

    public static boolean createPlaylist(User user, String name) {
        if (getPlaylistByName(user, name) != null) return false;

        PlayList newPlaylist = new PlayList(
                UUID.randomUUID().toString(),
                name

        );
        user.addPlaylist(newPlaylist);
        return true;
    }

    public static boolean deletePlaylist(User user, String name) {
        PlayList p = getPlaylistByName(user, name);
        if (p != null) {
            user.removePlaylist(p);
            return true;
        }
        return false;
    }

    public static boolean addSongToPlaylist(User user, String playlistName, Song song) {
        PlayList p = getPlaylistByName(user, playlistName);
        if (p != null && !p.getSongs().contains(song)) {
            p.addSong(song);
            return true;
        }
        return false;
    }

    public static boolean removeSongFromPlaylist(User user, String playlistName, Song song) {
        PlayList p = getPlaylistByName(user, playlistName);
        if (p != null && p.getSongs().contains(song)) {
            p.removeSong(song);
            return true;
        }
        return false;
    }

    public static List<Song> viewPlaylist(User user, String playlistName) {
        PlayList p = getPlaylistByName(user, playlistName);
        return p != null ? p.getSongs() : new ArrayList<>();
    }

    private static PlayList getPlaylistByName(User user, String name) {
        for (PlayList p : user.getPlaylists()) {
            if (p.getName().equalsIgnoreCase(name)) {
                return p;
            }
        }
        return null;
    }
}*/