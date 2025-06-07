import java.util.*;

public class User {
    private String id;
    private String username;
    private String password;
    private String email;
    private boolean isAdmin;
    private List<PlayList> playlists;
    private List<Song> likedSongs;
    private LinkedHashSet<Song> MostPlayedSongs;

    public User(String id, String username, String password, String email, boolean isAdmin) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.email = email;
        this.isAdmin = isAdmin;
        playlists = new ArrayList<>();
        likedSongs = new ArrayList<>();
    }

//getter setter

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public boolean isAdmin() {
        return isAdmin;
    }

    public void setAdmin(boolean admin) {
        isAdmin = admin;
    }

    public List<PlayList> getPlaylists() {
        return playlists;
    }

    public void setPlaylists(List<PlayList> playlists) {
        this.playlists = playlists;
    }

    public List<Song> getLikedSongs() {
        return likedSongs;
    }

    public void setLikedSongs(List<Song> likedSongs) {
        this.likedSongs = likedSongs;
    }

    //manage

    public void addPlaylist(PlayList playlist) {
        playlists.add(playlist);
    }

    public void removePlaylist(PlayList playlist) {
        playlists.remove(playlist);
    }

    public PlayList getPlaylistByName(String name) {
        for (PlayList playlist : playlists) {
            if (playlist.getName().equalsIgnoreCase(name)) {
                return playlist;
            }
        }
        return null;
    }

    public void updateProfile(String newUsername, String newEmail) {
        setUsername(newUsername);
        setEmail(newEmail);
    }

    public void changePassword(String newPassword) {
        setPassword(newPassword);
    }

    public void deleteAccount() {
        playlists.clear();
        likedSongs.clear();
    }
    //like and dislike

    public void likeSong(Song song) {
        if (!likedSongs.contains(song)) {
            likedSongs.add(song);
        }
    }


    public void disLikeSong(Song song) {
        if (likedSongs.contains(song)) {
            likedSongs.remove(song);
        }
    }
    public void addMostPlayedSong(Song song) {
        MostPlayedSongs.add(song);
    }
    public Set<Song> getMostPlayedSongsSortedSet(){
        List<Song> sortedSongs = new ArrayList<>(MostPlayedSongs);
        sortedSongs.sort((s1, s2) -> Integer.compare(s2.getPlayedCount(), s1.getPlayedCount()));
        List<Song> sortedList = new ArrayList<>(MostPlayedSongs);
        sortedList.sort((s1, s2) -> Integer.compare(s2.getPlayedCount(), s1.getPlayedCount()));
        return new LinkedHashSet<>(sortedList);


    }


    public boolean hasLikedSong(String songId) {
        return likedSongs.contains(songId);
    }



}
