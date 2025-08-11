 import java.util.*;

    public class Database {
        private static final List<User> users = new ArrayList<>();
        private static final List<Song> songs = new ArrayList<>();

        // --- User Methods ---

        public static void addUser(User user) {
            if (getUserByUsername(user.getUsername()) == null) {
                users.add(user);
                System.out.println("User added: " + user.getUsername());
            } else {
                System.out.println("Username already exists.");
            }
        }

        public static void removeUser(String username) {
            User user = getUserByUsername(username);
            if (user != null) {
                users.remove(user);
                System.out.println("User removed: " + username);
            } else {
                System.out.println("User not found.");
            }
        }

        public static User getUserByUsername(String username) {
            for (User u : users) {
                if (u.getUsername().equalsIgnoreCase(username)) {
                    return u;
                }
            }
            return null;
        }

        public static List<User> getAllUsers() {
            return users;
        }

        // --- Song Methods ---

        public static void addSong(Song song) {
            songs.add(song);
            System.out.println("Song added: " + song.getTitle());
        }

        public static void removeSong(String songId) {
            Song s = getSongById(songId);
            if (s != null) {
                songs.remove(s);
                System.out.println("Song removed: " + s.getTitle());
            } else {
                System.out.println("Song not found.");
            }
        }

        public static Song getSongById(String id) {
            for (Song s : songs) {
                if (s.getId().equals(id)) {
                    return s;
                }
            }
            return null;
        }

        public static List<Song> getAllSongs() {
            return songs;
        }

        public static List<Song> searchSongsByTitle(String keyword) {
            List<Song> result = new ArrayList<>();
            for (Song s : songs) {
                if (s.getTitle().toLowerCase().contains(keyword.toLowerCase())) {
                    result.add(s);
                }
            }
            return result;
        }

        // --- Utility for Debugging ---

        public static void printAllUsers() {
            System.out.println("---- Users ----");
            for (User u : users) {
                System.out.println(u);
            }
        }

        public static void printAllSongs() {
            System.out.println("---- Songs ----");
            for (Song s : songs) {
                System.out.println(s);
            }
        }
    }