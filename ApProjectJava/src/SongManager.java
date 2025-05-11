import java.util.*;
import java.util.stream.Collectors;

public class SongManager {

    public static List<Song> searchByTitle(String titleKeyword) {
        return Database.getAllSongs().stream()
                .filter(song -> song.getTitle().toLowerCase().contains(titleKeyword.toLowerCase()))
                .collect(Collectors.toList());
    }

    public static List<Song> filterByGenre(String genre) {
        return Database.getAllSongs().stream()
                .filter(song -> song.getGenre().equalsIgnoreCase(genre))
                .collect(Collectors.toList());
    }

    public static List<Song> sortByUploadDate() {
        return Database.getAllSongs().stream()
                .sorted(Comparator.comparing(Song::getReleaseDate).reversed())
                .collect(Collectors.toList());
    }

    public static List<Song> sortByAlphabet() {
        return Database.getAllSongs().stream()
                .sorted(Comparator.comparing(Song::getTitle))
                .collect(Collectors.toList());
    }

    public static List<Song> getMostLikedSongs(int limit) {
        return Database.getAllSongs().stream()
                .sorted(Comparator.comparingInt(Song::getLikeCount).reversed())
                .limit(limit)
                .collect(Collectors.toList());
    }
}