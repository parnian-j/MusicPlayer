import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.io.*;
import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

public class AdminCLI {

    private static final String USERS_FILE = "user_profiles.json";
    private static final String SONG_DATA_FILE = "song_data.json";
    private static final String SONGS_FOLDER = "server_songs";

    private final Gson gson = new GsonBuilder().setPrettyPrinting().create();

    private Map<String, Map<String, Object>> userProfiles = new LinkedHashMap<>();

    private Map<String, Integer> songLikes = new HashMap<>();
    private Map<String, Integer> songViews = new HashMap<>();

    private final Scanner scanner = new Scanner(System.in, StandardCharsets.UTF_8);

    public static void main(String[] args) {
        AdminCLI cli = new AdminCLI();
        cli.loadAll();
        cli.mainMenu();
        cli.saveAll();
        System.out.println("\nخروج از برنامه. تغییرات ذخیره شد.");
    }

    private void loadAll() {
        loadUserProfiles();
        loadSongData();
    }

    private void saveAll() {
        saveUserProfiles();
        saveSongData();
    }

    private void loadUserProfiles() {
        File f = new File(USERS_FILE);
        if (!f.exists()) {
            System.out.println("this " + USERS_FILE + "not found");
            userProfiles = new LinkedHashMap<>();
            return;
        }
        try (Reader r = new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8)) {
            Type t = new TypeToken<LinkedHashMap<String, LinkedHashMap<String, Object>>>() {
            }.getType();
            Map<String, Map<String, Object>> data = gson.fromJson(r, t);
            if (data != null) userProfiles = new LinkedHashMap<>(data);
        } catch (Exception e) {
            System.out.println("error " + USERS_FILE + ": " + e.getMessage());
            userProfiles = new LinkedHashMap<>();
        }
    }

    private void saveUserProfiles() {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(USERS_FILE), StandardCharsets.UTF_8)) {
            gson.toJson(userProfiles, w);
            System.out.println("\nuser profile saved " + USERS_FILE);
        } catch (Exception e) {
            System.out.println("error saving " + USERS_FILE + ": " + e.getMessage());
        }
    }

    private void loadSongData() {
        File f = new File(SONG_DATA_FILE);
        if (!f.exists()) {
            System.out.println("warning :  " + SONG_DATA_FILE + " not found");
            songLikes = new HashMap<>();
            songViews = new HashMap<>();
            return;
        }
        try (Reader r = new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8)) {
            Type t = new TypeToken<Map<String, Map<String, Double>>>() {
            }.getType();
            Map<String, Map<String, Double>> data = gson.fromJson(r, t);
            songLikes = new HashMap<>();
            songViews = new HashMap<>();
            if (data != null) {
                Map<String, Double> likes = data.getOrDefault("likes", Collections.emptyMap());
                for (Map.Entry<String, Double> e : likes.entrySet()) songLikes.put(e.getKey(), e.getValue().intValue());
                Map<String, Double> views = data.getOrDefault("views", Collections.emptyMap());
                for (Map.Entry<String, Double> e : views.entrySet()) songViews.put(e.getKey(), e.getValue().intValue());
            }
        } catch (Exception e) {
            System.out.println("error reading this" + SONG_DATA_FILE + ": " + e.getMessage());
            songLikes = new HashMap<>();
            songViews = new HashMap<>();
        }
    }

    private void saveSongData() {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(SONG_DATA_FILE), StandardCharsets.UTF_8)) {
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("likes", songLikes);
            out.put("views", songViews);
            gson.toJson(out, w);
            System.out.println("song details updated " + SONG_DATA_FILE);
        } catch (Exception e) {
            System.out.println("error saving" + SONG_DATA_FILE + ": " + e.getMessage());
        }
    }

    private void mainMenu() {
        while (true) {
            System.out.println("\n===== (AdminCLI) =====");
            System.out.println("1) user management");
            System.out.println("2) playlists");
            System.out.println("3) songs");
            System.out.println("4) printing");
            System.out.println("5) save changes");
            System.out.println("0) exit");
            System.out.print(" choose an option: ");
            String c = scanner.nextLine().trim();
            switch (c) {
                case "1":
                    usersMenu();
                    break;
                case "2":
                    playlistsMenu();
                    break;
                case "3":
                    songsMenu();
                    break;
                case "4":
                    reportsMenu();
                    break;
                case "5":
                    saveAll();
                    break;
                case "0":
                    return;
                default:
                    System.out.println("invalid option");
            }
        }
    }

    private void usersMenu() {
        while (true) {
            System.out.println("\n--- user management ---");
            System.out.println("1) show user profile");
            System.out.println("2) show");
            System.out.println("3) create user");
            System.out.println("4) delete user");
            System.out.println("5) update user profile");
            System.out.println("0) back");
            System.out.print("choose an option: ");
            String c = scanner.nextLine().trim();
            switch (c) {
                case "1":
                    listUsers();
                    break;
                case "2":
                    showUserProfile();
                    break;
                case "3":
                    createUser();
                    break;
                case "4":
                    deleteUser();
                    break;
                case "5":
                    updateUserFields();
                    break;
                case "0":
                    return;
                default:
                    System.out.println("invalid option");
            }
        }
    }

    private void listUsers() {
        if (userProfiles.isEmpty()) {
            System.out.println("No user profiles");
            return;
        }
        System.out.printf("\n%-20s | %-25s | %5s | %7s\n", "Username", "Email", "PLs", "Likes");
        System.out.println("-".repeat(64));
        for (Map.Entry<String, Map<String, Object>> e : userProfiles.entrySet()) {
            String u = e.getKey();
            Map<String, Object> p = e.getValue();
            String email = str(p.get("email"));
            int plSize = getPlaylists(p).size();
            int likedCount = getStringList(p.get("likedSongs")).size();
            System.out.printf("%-20s | %-25s | %5d | %7d\n", u, email, plSize, likedCount);
        }
    }

    private void showUserProfile() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }

        System.out.println("\n" + gson.toJson(p));
        System.out.println("\nSummary:");
        System.out.println("Email: " + str(p.get("email")));
        System.out.println("Theme: " + str(p.get("theme")));
        System.out.println("Number of playlists: " + getPlaylists(p).size());
        System.out.println("Number of liked songs: " + getStringList(p.get("likedSongs")).size());

        // Show only playlist names
        List<Map<String, Object>> playlists = getPlaylists(p);
        if (!playlists.isEmpty()) {
            System.out.println("Playlists:");
            for (Map<String, Object> pl : playlists) {
                System.out.println(" - " + getPlaylistName(pl));
            }
        } else {
            System.out.println("No playlists found.");
        }
    }


    private void createUser() {
        String u = prompt("new username: ");
        if (userProfiles.containsKey(u)) {
            System.out.println("already taken");
            return;
        }
        String email = prompt("emaiel: ");
        String pass = prompt("password: ");
        Map<String, Object> profile = new LinkedHashMap<>();
        profile.put("email", email);
        profile.put("password", pass);
        profile.put("theme", "light");
        profile.put("profileImage", null);
        profile.put("playlists", new ArrayList<>());
        profile.put("likedSongs", new ArrayList<>());
        profile.put("songs", new ArrayList<>());
        userProfiles.put(u, profile);
        saveUserProfiles();
        System.out.println("user created");
    }

    private void deleteUser() {
        String u = prompt("username: ");
        if (userProfiles.remove(u) != null) {
            saveUserProfiles();
            System.out.println("user deleted");
        } else {
            System.out.println("user not found.");
        }
    }

    private void updateUserFields() {
        String u = prompt("username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("user not found");
            return;
        }
        System.out.println("options 1)email   2) password  3) theme (light/dark)  0) back");
        String c = prompt("choose ");
        switch (c) {
            case "1":
                p.put("email", prompt("new email "));
                break;
            case "2":
                p.put("password", prompt("new password: "));
                break;
            case "3":
                p.put("theme", prompt("new theme(light/dark): "));
                break;
            case "0":
                return;
            default:
                System.out.println("invalid option");
                return;
        }
        saveUserProfiles();
        System.out.println("updated");
    }

    private void playlistsMenu() {
        while (true) {
            System.out.println("\n--- Playlist Management ---");
            System.out.println("1) Show user's playlists");
            System.out.println("2) Create new playlist");
            System.out.println("3) Rename playlist");
            System.out.println("4) Delete playlist");
            System.out.println("5) Add song to playlist");
            System.out.println("6) Remove song from playlist");
            System.out.println("0) Back");
            System.out.print("Choice: ");
            String c = scanner.nextLine().trim();
            switch (c) {
                case "1":
                    listUserPlaylists();
                    break;
                case "2":
                    createPlaylist();
                    break;
                case "3":
                    renamePlaylist();
                    break;
                case "4":
                    deletePlaylist();
                    break;
                case "5":
                    addSongToPlaylist();
                    break;
                case "6":
                    removeSongFromPlaylist();
                    break;
                case "0":
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }

    private void listUserPlaylists() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        List<Map<String, Object>> pls = getPlaylists(p);
        if (pls.isEmpty()) {
            System.out.println("No playlists found.");
            return;
        }
        System.out.printf("\nPlaylists of %s:\n", u);
        int idx = 1;
        for (Map<String, Object> pl : pls) {
            String name = getPlaylistName(pl);
            String id = str(pl.get("id"));
            List<String> songs = getPlaylistSongs(pl);
            System.out.printf("%d) %s %s  | %d songs\n", idx++, name, (id == null || id.isEmpty() ? "" : "[" + id + "]"), songs.size());
        }
    }

    private void createPlaylist() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        String name = prompt("Playlist name: ");
        List<Map<String, Object>> pls = getPlaylists(p);
        for (Map<String, Object> pl : pls) {
            if (name.equalsIgnoreCase(getPlaylistName(pl))) {
                System.out.println("A playlist with this name already exists.");
                return;
            }
        }
        Map<String, Object> newPl = new LinkedHashMap<>();
        newPl.put("id", UUID.randomUUID().toString());
        newPl.put("name", name);
        newPl.put("songs", new ArrayList<String>());
        pls.add(newPl);
        p.put("playlists", pls);
        saveUserProfiles();
        System.out.println("Playlist created successfully.");
    }


    private void renamePlaylist() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        List<Map<String, Object>> pls = getPlaylists(p);
        if (pls.isEmpty()) {
            System.out.println("No playlists found.");
            return;
        }
        String target = prompt("Current playlist name or ID: ");
        for (Map<String, Object> pl : pls) {
            if (matchesPlaylist(pl, target)) {
                String nn = prompt("New name: ");
                setPlaylistName(pl, nn);
                saveUserProfiles();
                System.out.println("Playlist renamed.");
                return;
            }
        }
        System.out.println("Playlist not found.");
    }

    private void deletePlaylist() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        List<Map<String, Object>> pls = getPlaylists(p);
        if (pls.isEmpty()) {
            System.out.println("No playlists found.");
            return;
        }
        String target = prompt("Playlist name or ID to delete: ");
        boolean removed = pls.removeIf(pl -> matchesPlaylist(pl, target));
        if (removed) {
            saveUserProfiles();
            System.out.println("Playlist deleted.");
        } else System.out.println("Playlist not found.");
    }

    private void addSongToPlaylist() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        List<Map<String, Object>> pls = getPlaylists(p);
        if (pls.isEmpty()) {
            System.out.println("No playlists found.");
            return;
        }
        String target = prompt("Playlist name or ID: ");
        Map<String, Object> found = findPlaylist(pls, target);
        if (found == null) {
            System.out.println("Playlist not found.");
            return;
        }
        String songId = prompt("songId (mp3 file name without extension): ");
        if (!songExists(songId)) {
            System.out.println("⚠ Song file not found in folder " + SONGS_FOLDER + " (" + songId + ".mp3)");
        }
        List<String> songs = getPlaylistSongs(found);
        if (!songs.contains(songId)) songs.add(songId);
        else {
            System.out.println("This song is already in the playlist.");
            return;
        }
        saveUserProfiles();
        System.out.println("Song added.");
    }

    private void removeSongFromPlaylist() {
        String u = prompt("Username: ");
        Map<String, Object> p = userProfiles.get(u);
        if (p == null) {
            System.out.println("User not found.");
            return;
        }
        List<Map<String, Object>> pls = getPlaylists(p);
        if (pls.isEmpty()) {
            System.out.println("No playlists found.");
            return;
        }
        String target = prompt("Playlist name or ID: ");
        Map<String, Object> found = findPlaylist(pls, target);
        if (found == null) {
            System.out.println("Playlist not found.");
            return;
        }
        String songId = prompt("songId to remove: ");
        List<String> songs = getPlaylistSongs(found);
        if (songs.remove(songId)) {
            saveUserProfiles();
            System.out.println("Removed.");
        } else System.out.println("This song was not in the playlist.");
    }

    private void songsMenu() {
        while (true) {
            System.out.println("\n--- Songs & Stats Management ---");
            System.out.println("1) Show Top Liked");
            System.out.println("2) Show Top Viewed");
            System.out.println("3) Set/Edit likes count for a song");
            System.out.println("4) Set/Edit views count for a song");
            System.out.println("5) Search song presence in playlists");
            System.out.println("0) Back");
            System.out.print("Choice: ");
            String c = scanner.nextLine().trim();
            switch (c) {
                case "1":
                    showTop(songLikes, "Likes");
                    break;
                case "2":
                    showTop(songViews, "Views");
                    break;
                case "3":
                    setCounter(songLikes, "Likes");
                    break;
                case "4":
                    setCounter(songViews, "Views");
                    break;
                case "5":
                    searchSongPresence();
                    break;
                case "0":
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }

    private void showTop(Map<String, Integer> map, String label) {
        int n = parseIntSafe(prompt("Number N: "), 10);
        List<Map.Entry<String, Integer>> list = new ArrayList<>(map.entrySet());
        list.sort((a, b) -> Integer.compare(b.getValue(), a.getValue()));
        System.out.printf("\nTop %d by %s:\n", n, label);
        System.out.println("-".repeat(40));
        int i = 1;
        for (Map.Entry<String, Integer> e : list) {
            System.out.printf("%2d) %-25s | %s: %d %s\n", i++, e.getKey(), label, e.getValue(),
                    songExists(e.getKey()) ? "" : "(File not found)");
            if (i > n) break;
        }
        if (list.isEmpty()) System.out.println("No data available.");
    }

    private void setCounter(Map<String, Integer> map, String label) {
        String songId = prompt("songId: ");
        int val = parseIntSafe(prompt("New value for " + label + ": "), 0);
        map.put(songId, val);
        saveSongData();
        System.out.println("Updated.");
    }

    private void searchSongPresence() {
        String songId = prompt("songId: ");
        int inPlaylists = 0;
        List<String> owners = new ArrayList<>();
        for (Map.Entry<String, Map<String, Object>> e : userProfiles.entrySet()) {
            List<Map<String, Object>> pls = getPlaylists(e.getValue());
            for (Map<String, Object> pl : pls) {
                if (getPlaylistSongs(pl).contains(songId)) {
                    inPlaylists++;
                    owners.add(e.getKey() + ":" + getPlaylistName(pl));
                }
            }
        }
        System.out.println("\nSong file: " + (songExists(songId) ? "✅ Exists" : "❌ Not found"));
        System.out.println("Present in playlists: " + inPlaylists);
        if (!owners.isEmpty()) System.out.println("Owner/Playlist list: " + owners);
        System.out.println("Likes: " + songLikes.getOrDefault(songId, 0) +
                " | Views: " + songViews.getOrDefault(songId, 0));
    }

    private void reportsMenu() {
        while (true) {
            System.out.println("\n--- Reports / Export ---");
            System.out.println("1) Export users summary CSV");
            System.out.println("2) Export Top Liked/Viewed CSV");
            System.out.println("0) Back");
            System.out.print("Choice: ");
            String c = scanner.nextLine().trim();
            switch (c) {
                case "1":
                    exportUsersCsv();
                    break;
                case "2":
                    exportTopCsv();
                    break;
                case "0":
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }

    private void exportUsersCsv() {
        String path = prompt("CSV file path (default users_report.csv): ");
        if (path.isEmpty()) path = "users_report.csv";
        try (BufferedWriter bw = Files.newBufferedWriter(Paths.get(path), StandardCharsets.UTF_8)) {
            bw.write("username,email,playlists_count,liked_songs_count\n");
            for (Map.Entry<String, Map<String, Object>> e : userProfiles.entrySet()) {
                String u = e.getKey();
                Map<String, Object> p = e.getValue();
                String email = str(p.get("email"));
                int plSize = getPlaylists(p).size();
                int likedCount = getStringList(p.get("likedSongs")).size();
                bw.write(String.join(",",
                        csv(u), csv(email), String.valueOf(plSize), String.valueOf(likedCount)) + "\n");
            }
            System.out.println("✔ Report generated: " + path);
        } catch (Exception ex) {
            System.out.println("❌ Error generating CSV: " + ex.getMessage());
        }
    }

    private void exportTopCsv() {
        String path = prompt("CSV file path (default songs_top.csv): ");
        if (path.isEmpty()) path = "songs_top.csv";
        int n = parseIntSafe(prompt("N for export: "), 20);
        try (BufferedWriter bw = Files.newBufferedWriter(Paths.get(path), StandardCharsets.UTF_8)) {
            bw.write("rank,songId,likes,views,file_exists\n");
            // Sort by likes
            List<Map.Entry<String, Integer>> list = new ArrayList<>(songLikes.entrySet());
            list.sort((a, b) -> Integer.compare(b.getValue(), a.getValue()));
            int i = 1;
            for (Map.Entry<String, Integer> e : list) {
                String id = e.getKey();
                bw.write(i + "," + csv(id) + "," + e.getValue() + ","
                        + songViews.getOrDefault(id, 0) + ","
                        + (songExists(id) ? "yes" : "no") + "\n");
                if (++i > n) break;
            }
            System.out.println("✔ Report generated: " + path);
        } catch (Exception ex) {
            System.out.println("❌ Error generating CSV: " + ex.getMessage());
        }
    }

    private String prompt(String msg) {
        System.out.print(msg);
        return scanner.nextLine().trim();
    }

    private String str(Object o) {
        return o == null ? null : String.valueOf(o);
    }

    private int parseIntSafe(String s, int def) {
        try {
            return Integer.parseInt(s.trim());
        } catch (Exception e) {
            return def;
        }
    }

    private String csv(String s) {
        if (s == null) return "";
        if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            return '"' + s.replace("\"", "\"\"") + '"';
        }
        return s;
    }

    private boolean songExists(String songId) {
        if (songId == null || songId.isEmpty()) return false;
        File f = new File(SONGS_FOLDER, songId + ".mp3");
        return f.exists() && f.isFile();
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> getPlaylists(Map<String, Object> profile) {
        Object pls = profile.get("playlists");
        if (pls instanceof List) return (List<Map<String, Object>>) pls;
        List<Map<String, Object>> empty = new ArrayList<>();
        profile.put("playlists", empty); // normalize
        return empty;
    }

    private boolean matchesPlaylist(Map<String, Object> pl, String token) {
        String id = str(pl.get("id"));
        String name = getPlaylistName(pl);
        return token.equalsIgnoreCase(id == null ? "" : id) || token.equalsIgnoreCase(name == null ? "" : name);
    }

    private String getPlaylistName(Map<String, Object> pl) {
        Object name = pl.get("name");
        if (name == null) name = pl.get("playlistName");
        return name == null ? null : String.valueOf(name);
    }

    private void setPlaylistName(Map<String, Object> pl, String newName) {
        pl.put("name", newName);

        if (pl.containsKey("playlistName")) pl.put("playlistName", newName);
    }

    private List<String> getPlaylistSongs(Map<String, Object> pl) {
        Object s = pl.get("songs");
        if (s instanceof List) {

            List<?> raw = (List<?>) s;
            List<String> casted = new ArrayList<>();
            for (Object o : raw) casted.add(String.valueOf(o));
            pl.put("songs", casted);
            return casted;
        }
        List<String> empty = new ArrayList<>();
        pl.put("songs", empty);
        return empty;
    }

    private List<String> getStringList(Object o) {
        if (o instanceof List) {
            List<?> raw = (List<?>) o;
            List<String> res = new ArrayList<>();
            for (Object x : raw) res.add(String.valueOf(x));
            return res;
        }
        return new ArrayList<>();
    }

    private Map<String, Object> findPlaylist(List<Map<String, Object>> playlists, String token) {
        for (Map<String, Object> pl : playlists) {
            if (matchesPlaylist(pl, token)) return pl;
        }
        return null;
    }
}


