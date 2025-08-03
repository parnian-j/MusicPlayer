import java.time.LocalDate;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class Song {
    private int id;
    private static int ID=0;
    private String title;
    private String artist;
    private String album;
    private String genre;
    private int duration;
    private String path;
    private String releaseDate;
    private int likeCount;
    private int playedCount;
    private static final Map<Integer, Song> userMap = new HashMap<>();
    private Set<String> likedByUsers = new HashSet<>();

    public boolean like(String username) {
        if (likedByUsers.contains(username)) {
            return false; // قبلاً لایک کرده
        }
        likedByUsers.add(username);
        this.likeCount++;
        return true;
    }
    public boolean unlike(String username) {
        if (!likedByUsers.contains(username)) {
            return false;
        }
        likedByUsers.remove(username);
        likeCount--;
        return true;
    }


    public Song(String title,String artist){
        ID++;
        this.id = ID;
        this.title = title;
        this.artist = artist;
        userMap.put(ID, this);
    }

    public Song(int id, String title, String artist, String album, String genre, int duration, String path, int likeCount) {
        ID++;
        this.id = ID;
        this.title = title;
        this.artist = artist;
        this.album = album;
        this.genre = genre;
        this.duration = duration;
        this.path = path;
        this.likeCount = likeCount;
        userMap.put(ID, this);
    }


    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getArtist() {
        return artist;
    }

    public void setArtist(String artist) {
        this.artist = artist;
    }

    public String getAlbum() {
        return album;
    }

    public void setAlbum(String album) {
        this.album = album;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public int getDuration() {
        return duration;
    }

    public void setDuration(int duration) {
        this.duration = duration;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getReleaseDate() {
        return releaseDate;
    }

    public void setReleaseDate(String releaseDate) {
        this.releaseDate = releaseDate;
    }

    public int getLikeCount() {
        return likeCount;
    }

    public void setLikeCount(int likeCount) {
        this.likeCount = likeCount;
    }
    public static Song FindByID(int id) {
        Song song = userMap.get(id);
        return song;

    }

    public boolean equals(Song song) {
        if (this.id == song.id){
        return true;
        }
        return false;

    }
    public void addPlayedCount() {
        this.playedCount = this.playedCount + 1;
    }

    public int getPlayedCount() {
        return playedCount;
    }
}
