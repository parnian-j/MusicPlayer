import java.util.*;

public class PlayList {
    private int id;
    private static int PlayListID = 0;
    private String name;
    private List<Song> songs;
    private boolean isPrivate ;
    public static Map<Integer, PlayList> playlists = new HashMap<>();
    public PlayList(String name, boolean isPrivate) {
        PlayListID++;
        this.id = PlayListID;
        this.name = name;
        playlists.put(PlayListID, this);
        this.isPrivate = isPrivate;
    }
    public static PlayList getPLayList(int id) {
        PlayList m = playlists.get(id);
        if (m == null) {
            return null;
        }
        return m;
    }


    public static Integer getId(PlayList target) {
        for (Map.Entry<Integer, PlayList> entry : playlists.entrySet()) {
            if (entry.getValue().equals(target)) {
                return entry.getKey();
            }
        }
        return null;
    }

    private static PlayList getPlaylistByName(String name) {
        for(PlayList pl : playlists.values()) {
            if (pl.getName().equalsIgnoreCase(name) && !pl.isPrivate) {
                return pl;
            }
        }
        return null;
    }

    public String getName() {
        return name;
    }
    public List<Song> getSongs() {
        return songs;
    }
    /*public void setId(int id) {
        this.id = id;
    }*/
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

}
