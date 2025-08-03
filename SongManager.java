import java.util.*;
import java.util.stream.Collectors;

public class SongManager {

    private static List<Song> getAllSongs() {
        return Database.getAllSongs(); // خلاصه‌سازی و جلوگیری از تکرار
    }

    public static List<Song> searchByTitle(String keyword) {
        if (keyword == null || keyword.isEmpty()) return Collections.emptyList();

        return getAllSongs().stream()
                .filter(song -> song.getTitle() != null &&
                        song.getTitle().toLowerCase().contains(keyword.toLowerCase()))
                .collect(Collectors.toList());
    }

    public static List<Song> filterByGenre(String genre) {
        if (genre == null || genre.isEmpty()) return Collections.emptyList();

        return getAllSongs().stream()
                .filter(song -> genre.equalsIgnoreCase(song.getGenre()))
                .collect(Collectors.toList());
    }

    public static List<Song> sortByUploadDate() {
        return getAllSongs().stream()
                .filter(song -> song.getReleaseDate() != null)
                .sorted(Comparator.comparing(Song::getReleaseDate).reversed())
                .collect(Collectors.toList());
    }

    public static List<Song> sortByAlphabet() {
        return getAllSongs().stream()
                .filter(song -> song.getTitle() != null)
                .sorted(Comparator.comparing(Song::getTitle, String.CASE_INSENSITIVE_ORDER))
                .collect(Collectors.toList());
    }

    public static List<Song> getMostLikedSongs(int limit) {
        if (limit <= 0) return Collections.emptyList();

        return getAllSongs().stream()
                .sorted(Comparator.comparingInt(Song::getLikeCount).reversed())
                .limit(limit)
                .collect(Collectors.toList());
    }
}
