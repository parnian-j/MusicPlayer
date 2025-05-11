import java.util.*;

public class PlayList {
    private String id;
    private String name;
    private List<Song> songs;
    public PlayList(String id, String name, List<Song> songs) {
        this.id = id;
        this.name = name;
        this.songs = songs;
    }
    public String getId() {
        return id;
    }
    public String getName() {
        return name;
    }
    public List<Song> getSongs() {
        return songs;
    }
    public void setId(String id) {
        this.id = id;
    }
    public void setName(String name) {
        this.name = name;
    }
    public void setSongs(List<Song> songs) {
        this.songs = songs;
    }
    public void addSong(Song song) {
        songs.add(song);
    }
    public void removeSong(Song song) {
        songs.remove(song);
    }
    pu
}
