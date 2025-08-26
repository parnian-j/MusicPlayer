import com.google.gson.reflect.TypeToken;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import com.google.gson.Gson;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import java.io.*;
import java.lang.reflect.Type;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class SimpleServer {

    private static final String HOST_IP = "192.168.219.134";
    private static final int HTTP_PORT = 8080;
    private static final int TCP_PORT = 12344;
    private static final int WEBSOCKET_PORT = 12345;
    private static final String SONGS_FOLDER = "server_songs";
    private static final String USERS_FILE = "user_profiles.json";

    private static Map<String, Integer> songLikes = new HashMap<>();
    private static Map<String, Integer> songViews = new HashMap<>();
    private static Map<String, Map<String, Object>> userProfiles = new HashMap<>();

    private static Gson gson = new Gson();

    public static void main(String[] args) throws Exception {
        loadSongData();
        loadUserProfiles();
        startHttpFileServer();
        startTcpSocketServer();
        startWebSocketServer();
    }

    private static void loadSongData() {
        File file = new File("song_data.json");
        if (file.exists()) {
            try (FileReader reader = new FileReader(file)) {
                Map<String, Map<String, Double>> data = gson.fromJson(reader, Map.class);
                if (data != null) {
                    data.getOrDefault("likes", new HashMap<>())
                            .forEach((k, v) -> songLikes.put(k, v.intValue()));
                    data.getOrDefault("views", new HashMap<>())
                            .forEach((k, v) -> songViews.put(k, v.intValue()));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private static void saveSongData() {
        try (FileWriter writer = new FileWriter("song_data.json")) {
            Map<String, Object> data = new HashMap<>();
            data.put("likes", songLikes);
            data.put("views", songViews);
            gson.toJson(data, writer);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void loadUserProfiles() {
        File file = new File(USERS_FILE);
        if (file.exists()) {
            try (FileReader reader = new FileReader(file)) {
                Map<String, Map<String, Object>> data = gson.fromJson(reader, Map.class);
                if (data != null) {
                    userProfiles.putAll(data);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private static void saveUserProfiles() {
        try (FileWriter writer = new FileWriter(USERS_FILE)) {
            gson.toJson(userProfiles, writer);
            System.out.println("User profiles saved to file.");
        } catch (IOException e) {
            System.out.println("Error saving user profiles: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void startHttpFileServer() throws IOException {
        HttpServer httpServer = HttpServer.create(new InetSocketAddress(HTTP_PORT), 0);
        httpServer.createContext("/songs", new HttpHandler() {
            @Override
            public void handle(HttpExchange exchange) throws IOException {
                if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(405, -1);
                    return;
                }

                String path = exchange.getRequestURI().getPath();
                String filename = path.replaceFirst("/songs/?", "");
                if (filename.isEmpty()) {
                    exchange.sendResponseHeaders(400, -1);
                    return;
                }

                File file = new File(SONGS_FOLDER, filename);
                if (!file.exists() || !file.isFile()) {
                    exchange.sendResponseHeaders(404, -1);
                    return;
                }

                exchange.getResponseHeaders().add("Content-Type", "audio/mpeg");
                long length = file.length();
                exchange.sendResponseHeaders(200, length);

                try (OutputStream os = exchange.getResponseBody();
                     FileInputStream fis = new FileInputStream(file)) {
                    byte[] buffer = new byte[8192];
                    int read;
                    while ((read = fis.read(buffer)) != -1) {
                        os.write(buffer, 0, read);
                    }
                }
            }
        });
        httpServer.setExecutor(java.util.concurrent.Executors.newCachedThreadPool());
        httpServer.start();
        System.out.println("HTTP file server started on port " + HTTP_PORT + " serving folder '" + SONGS_FOLDER + "'");
    }

    private static void startTcpSocketServer() {
        new Thread(() -> {
            try (ServerSocket serverSocket = new ServerSocket(TCP_PORT)) {
                System.out.println("TCP Socket server started on port " + TCP_PORT);
                while (true) {
                    Socket socket = serverSocket.accept();
                    System.out.println("TCP client connected: " + socket.getRemoteSocketAddress());
                    new Thread(() -> handleTcpClient(socket)).start();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();
    }


    private static void handleTcpClient(Socket socket) {
        try {
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            OutputStream outputStream = socket.getOutputStream();

            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                System.out.println("Received data from Flutter: " + inputLine);

                try {
                    if (inputLine.startsWith("{")) {
                        Request request = gson.fromJson(inputLine, Request.class);
                        String response = "";

                        switch (request.getAction()) {
                            case "delete_playlist": {
                                String payloadJson = request.getPayloadJson();
                                System.out.println("Received request to delete playlist: " + payloadJson);
                                Map<String, Object> payloadMap = gson.fromJson(payloadJson, Map.class);
                                String usernameProfile = (String) payloadMap.get("username");
                                String playlistId = (String) payloadMap.get("playlistId");
                                System.out.println("Deleting playlist for username: " + usernameProfile + " with playlistId: " + playlistId);
                                Map<String, Object> userProfile = userProfiles.getOrDefault(usernameProfile, new HashMap<>());
                                if (!userProfile.isEmpty()) {
                                    List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");
                                    playlists.removeIf(playlist -> playlistId.equals(playlist.get("id")));
                                    System.out.println("Playlist removed successfully for username: " + usernameProfile);
                                    userProfiles.put(usernameProfile, userProfile);

                                    Map<String, Object> responseMap = new HashMap<>();
                                    responseMap.put("status", "success");
                                    response = gson.toJson(responseMap);
                                } else {
                                    Map<String, Object> responseMap = new HashMap<>();
                                    responseMap.put("status", "error");
                                    response = gson.toJson(responseMap);
                                }
                                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                                outputStream.flush();

                                break;
                            }

                            case "create_playlist": {
                                String payloadJson = request.getPayloadJson();
                                Map<String, String> playlistPayload = gson.fromJson(payloadJson, Map.class);
                                String username = playlistPayload.get("username");
                                String playlistName = playlistPayload.get("playlistName");
                                String playlistId = UUID.randomUUID().toString();

                                if (!userProfiles.containsKey(username)) {
                                    response = "User not found";
                                } else {
                                    Map<String, Object> userProfile = userProfiles.get(username);
                                    List<Map<String, String>> playlists = (List<Map<String, String>>) userProfile.getOrDefault("playlists", new ArrayList<>());
                                    playlists.add(Map.of("id", playlistId, "name", playlistName));

                                    userProfile.put("playlists", playlists);
                                    saveUserProfiles();
                                    response = "Playlist created successfully";
                                    Map<String, Object> playlistData = Map.of(
                                            "id", playlistId,
                                            "name", playlistName
                                    );
                                    String jsonResponse = gson.toJson(playlistData);
                                    outputStream.write((jsonResponse + "\n").getBytes(StandardCharsets.UTF_8));
                                    outputStream.flush();
                                }
                                break;
                            }


                            case "login": {
                                LoginRequest loginRequest = gson.fromJson(request.getPayloadJson(), LoginRequest.class);
                                response = handleLogin(loginRequest.getUsername(), loginRequest.getPassword());
                                break;
                            }

                            case "signup": {
                                Map<String, String> signupPayload = gson.fromJson(request.getPayloadJson(), Map.class);
                                response = handleSignup(signupPayload);
                                break;
                            }

                            case "like_song": {
                                String songIdLike = request.getPayloadJson().replace("\"", "");
                                songLikes.put(songIdLike, songLikes.getOrDefault(songIdLike, 0) + 1);
                                saveSongData();
                                response = "success";
                                break;
                            }

                            case "increment_view": {
                                String songIdView = request.getPayloadJson().replace("\"", "");
                                songViews.put(songIdView, songViews.getOrDefault(songIdView, 0) + 1);
                                saveSongData();
                                response = "success";
                                break;
                            }

                            case "get_profile": {
                                String payloadJson = request.getPayloadJson();
                                System.out.println("Received request for user profile: " + payloadJson);

                                Map<String, Object> payloadMap = gson.fromJson(payloadJson, Map.class);
                                String usernameProfile = (String) payloadMap.get("username");

                                // لاگ برای بررسی نام کاربری که به سرور ارسال شده است
                                System.out.println("Requested profile for username: " + usernameProfile);

                                // بررسی اینکه آیا پروفایل برای این کاربر موجود است
                                Map<String, Object> userProfile = userProfiles.getOrDefault(usernameProfile, new HashMap<>());

                                // استخراج پلی‌لیست‌ها و آهنگ‌ها از پروفایل
                                // (بدون استفاده از Set و حذف تکراری)
                                List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");
                                List<Map<String, Object>> songs = (List<Map<String, Object>>) userProfile.get("songs");

                                // قرار دادن پلی‌لیست‌ها و آهنگ‌ها در پروفایل
                                userProfile.put("playlists", playlists);
                                userProfile.put("songs", songs);

                                // تبدیل پروفایل به JSON و ارسال به کلاینت
                                response = gson.toJson(userProfile); // ارسال پروفایل به صورت JSON
                                System.out.println("Response to be sent to client: " + response);  // لاگ برای بررسی پاسخ

                                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                                outputStream.flush();

                                break;
                            }


                            case "update_theme": {
                                // بروزرسانی تم کاربر
                                Map<String, String> themePayload = gson.fromJson(request.getPayloadJson(), Map.class);
                                String userTheme = themePayload.get("username");
                                String theme = themePayload.get("theme");
                                if (userProfiles.containsKey(userTheme)) {
                                    userProfiles.get(userTheme).put("theme", theme);
                                    saveUserProfiles();  // ذخیره تغییرات به فایل
                                    response = "theme updated";
                                } else {
                                    response = "user not found";
                                }
                                break;
                            }

                            case "update_profile": {
                                // بروزرسانی پروفایل کاربر
                                Map<String, Object> updatePayload = gson.fromJson(request.getPayloadJson(), Map.class);
                                String updateUser = (String) updatePayload.get("username");

                                if (updateUser != null && userProfiles.containsKey(updateUser)) {
                                    Map<String, Object> profile = userProfiles.get(updateUser);

                                    if (updatePayload.containsKey("email")) {
                                        profile.put("email", updatePayload.get("email"));
                                    }
                                    if (updatePayload.containsKey("password")) {
                                        profile.put("password", updatePayload.get("password"));
                                    }
                                    if (updatePayload.containsKey("theme")) {
                                        profile.put("theme", updatePayload.get("theme"));
                                    }
                                    if (updatePayload.containsKey("profileImage")) {
                                        profile.put("profileImage", updatePayload.get("profileImage"));
                                    }

                                    saveUserProfiles();  // ذخیره تغییرات به فایل
                                    response = "profile updated";
                                } else {
                                    response = "user not found";
                                }
                                break;
                            }

                            case "delete_account": {
                                // حذف حساب کاربر
                                String deleteUser = request.getPayloadJson().replace("\"", "");
                                if (deleteUser != null && userProfiles.containsKey(deleteUser)) {
                                    userProfiles.remove(deleteUser);
                                    saveUserProfiles();  // ذخیره روی فایل
                                    response = "success";
                                } else {
                                    response = "user not found";
                                }
                                break;
                            }


                            case "add_song_to_playlist": {
                                String payloadJson = request.getPayloadJson();
                                Map<String, String> payload = gson.fromJson(payloadJson, Map.class);
                                String username = payload.get("username");
                                String playlistName = payload.get("playlistName");
                                String songId = payload.get("songId");

                                if (!userProfiles.containsKey(username)) {
                                    response = "User not found";
                                } else {
                                    Map<String, Object> userProfile = userProfiles.get(username);
                                    List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

                                    for (Map<String, Object> playlist : playlists) {
                                        if (playlist.get("name").equals(playlistName)) {
                                            List<String> songs = (List<String>) playlist.get("songs");
                                            if (!songs.contains(songId)) {
                                                songs.add(songId);  // اضافه کردن آهنگ به پلی‌لیست
                                                saveUserProfiles();  // ذخیره تغییرات به فایل
                                                response = "Song added to playlist successfully";
                                            } else {
                                                response = "Song already in playlist";
                                            }
                                            break;
                                        }
                                    }
                                }
                                break;
                            }

                            case "add_song_to_profile": {
                                // دریافت اطلاعات آهنگ و نام کاربری از payload
                                String payloadJson = request.getPayloadJson();  // دریافت payload
                                System.out.println("Received request to add song to profile: " + payloadJson);  // لاگ برای بررسی

                                // از payload، username و songId را استخراج می‌کنیم
                                Map<String, Object> payloadMap = gson.fromJson(payloadJson, Map.class);
                                String usernameProfile = (String) payloadMap.get("username");
                                String songId = (String) payloadMap.get("songId");

                                // لاگ برای بررسی اطلاعات دریافتی
                                System.out.println("Adding song with id: " + songId + " to profile for username: " + usernameProfile);

                                // دریافت پروفایل کاربر از userProfiles
                                Map<String, Object> userProfile = userProfiles.getOrDefault(usernameProfile, new HashMap<>());

                                // اگر پروفایل کاربر موجود است
                                if (!userProfile.isEmpty()) {
                                    // دریافت آهنگ‌های موجود در پروفایل
                                    List<Map<String, Object>> songs = (List<Map<String, Object>>) userProfile.get("songs");

                                    // اگر آهنگ‌ها موجود نیستند، یک لیست خالی ایجاد می‌کنیم
                                    if (songs == null) {
                                        songs = new ArrayList<>();
                                    }

                                    // افزودن آهنگ جدید به پروفایل
                                    Map<String, Object> newSong = new HashMap<>();
                                    newSong.put("id", songId);  // افزودن آهنگ جدید با id مشخص

                                    // افزودن آهنگ جدید به لیست آهنگ‌ها
                                    songs.add(newSong);
                                    userProfile.put("songs", songs);  // ذخیره تغییرات در پروفایل

                                    // ذخیره‌سازی اطلاعات به روز شده کاربر
                                    userProfiles.put(usernameProfile, userProfile);
                                    System.out.println("Song added successfully to profile for username: " + usernameProfile);

                                    // ارسال پاسخ موفقیت به فلاتر
                                    Map<String, Object> responseMap = new HashMap<>();
                                    responseMap.put("status", "success");
                                    response = gson.toJson(responseMap);
                                } else {
                                    // اگر پروفایل کاربر یافت نشد
                                    Map<String, Object> responseMap = new HashMap<>();
                                    responseMap.put("status", "error");
                                    response = gson.toJson(responseMap);
                                }

                                // ارسال پاسخ به فلاتر
                                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                                outputStream.flush();

                                break;
                            }


                            case "remove_song_from_playlist": {
                                String payloadJson = request.getPayloadJson();
                                Map<String, String> payload = gson.fromJson(payloadJson, Map.class);
                                String username = payload.get("username");
                                String playlistName = payload.get("playlistName");
                                String songId = payload.get("songId");

                                if (!userProfiles.containsKey(username)) {
                                    response = "User not found";
                                } else {
                                    Map<String, Object> userProfile = userProfiles.get(username);
                                    List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

                                    for (Map<String, Object> playlist : playlists) {
                                        if (playlist.get("name").equals(playlistName)) {
                                            List<String> songs = (List<String>) playlist.get("songs");
                                            if (songs.contains(songId)) {
                                                songs.remove(songId);  // حذف آهنگ از پلی‌لیست
                                                saveUserProfiles();  // ذخیره تغییرات به فایل
                                                response = "Song removed from playlist successfully";
                                            } else {
                                                response = "Song not found in playlist";
                                            }
                                            break;
                                        }
                                    }
                                }
                                break;
                            }


                            default:
                                response = "Invalid action";
                        }

                        // ارسال پاسخ به کلاینت
                        outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                        outputStream.flush();
                    } else {
                        // اگر داده‌ها به درستی JSON نباشند، خطا بدهید
                        System.out.println("Invalid JSON format received: " + inputLine);
                        outputStream.write("Invalid JSON format\n".getBytes(StandardCharsets.UTF_8));
                        outputStream.flush();
                    }
                } catch (Exception e) {
                    System.out.println("Error processing JSON: " + e.getMessage());
                    outputStream.write("Error processing JSON\n".getBytes(StandardCharsets.UTF_8));
                    outputStream.flush();
                }
            }

            socket.close();
        } catch (IOException e) {
            System.out.println("TCP client connection error: " + e.getMessage());
        }
    }


    // -------------------- LOGIN / SIGNUP --------------------
    private static String handleLogin(String username, String password) {
        if (!userProfiles.containsKey(username)) {
            return "user not found";
        }
        String savedPassword = (String) userProfiles.get(username).get("password");
        if (password != null && password.equals(savedPassword)) {
            // مطابق با شرط کلاینت شما: contains('welcome')
            return "Welcome, " + username;
        } else {
            return "wrong password";
        }
    }

    private static String handleCreatePlaylist(String username, String playlistName) {
        if (!userProfiles.containsKey(username)) {
            return "user not found";
        }

        Map<String, Object> userProfile = userProfiles.get(username);
        List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

        // چک کردن اینکه آیا پلی‌لیست با این نام وجود دارد یا خیر
        for (Map<String, Object> playlist : playlists) {
            if (playlist.get("playlistName").equals(playlistName)) {
                return "playlist already exists";  // اگر پلی‌لیست قبلاً وجود داشته باشد
            }
        }

        // ایجاد پلی‌لیست جدید
        Map<String, Object> newPlaylist = new HashMap<>();
        newPlaylist.put("playlistName", playlistName);
        newPlaylist.put("songs", new ArrayList<>());  // آهنگ‌های این پلی‌لیست

        // افزودن پلی‌لیست به لیست پلی‌لیست‌ها
        playlists.add(newPlaylist);

        // ذخیره تغییرات به فایل
        saveUserProfiles();

        return "playlist created successfully";
    }


    private static String handleAddSongToPlaylist(String username, String playlistName, String songId) {
        if (!userProfiles.containsKey(username)) {
            return "user not found";
        }

        Map<String, Object> userProfile = userProfiles.get(username);
        List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

        // یافتن پلی‌لیست مورد نظر
        for (Map<String, Object> playlist : playlists) {
            if (playlist.get("playlistName").equals(playlistName)) {
                List<String> songs = (List<String>) playlist.get("songs");
                // اضافه کردن آهنگ به پلی‌لیست
                if (!songs.contains(songId)) {
                    songs.add(songId);
                    saveUserProfiles();  // ذخیره تغییرات به فایل
                    return "Song added to playlist successfully";
                } else {
                    return "Song already in playlist";  // اگر آهنگ قبلاً در پلی‌لیست موجود باشد
                }
            }
        }

        return "Playlist not found";  // اگر پلی‌لیست پیدا نشد
    }


    private static String handleRemoveSongFromPlaylist(String username, String playlistName, String songId) {
        if (!userProfiles.containsKey(username)) {
            return "user not found";
        }

        Map<String, Object> userProfile = userProfiles.get(username);
        List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

        // یافتن پلی‌لیست مورد نظر
        for (Map<String, Object> playlist : playlists) {
            if (playlist.get("playlistName").equals(playlistName)) {
                List<String> songs = (List<String>) playlist.get("songs");
                if (songs.contains(songId)) {
                    songs.remove(songId);  // حذف آهنگ از پلی‌لیست
                    saveUserProfiles();  // ذخیره تغییرات به فایل
                    return "Song removed from playlist successfully";
                } else {
                    return "Song not found in playlist";  // اگر آهنگ در پلی‌لیست نبود
                }
            }
        }

        return "Playlist not found";  // اگر پلی‌لیست پیدا نشد
    }


    private static String handleGetPlaylists(String username) {
        if (!userProfiles.containsKey(username)) {
            return "user not found";
        }

        Map<String, Object> userProfile = userProfiles.get(username);
        List<Map<String, Object>> playlists = (List<Map<String, Object>>) userProfile.get("playlists");

        // تبدیل پلی‌لیست‌ها به JSON
        return gson.toJson(playlists);
    }


    private static String handleSignup(Map<String, String> payload) {
        String username = payload.get("username");
        String password = payload.get("password");
        String email = payload.get("email");

        System.out.println("Received signup data: " + payload);

        if (username == null || username.trim().isEmpty()) return "invalid username";
        if (password == null || password.trim().isEmpty()) return "invalid password";
        if (email == null || email.trim().isEmpty()) return "invalid email";

        // چک کردن اینکه آیا نام کاربری قبلاً وجود دارد
        if (userProfiles.containsKey(username)) return "username already taken";

        // بررسی ایمیل
        for (Map<String, Object> profile : userProfiles.values()) {
            Object em = profile.get("email");
            if (em != null && email.equals(em.toString())) return "email already taken";
        }

        // ایجاد پروفایل جدید و اضافه کردن آن به userProfiles
        Map<String, Object> newProfile = new HashMap<>();
        newProfile.put("email", email);
        newProfile.put("password", password);
        newProfile.put("theme", "light");
        newProfile.put("profileImage", null);

        // افزودن لیست‌های اولیه
        List<Map<String, Object>> playlists = new ArrayList<>();
        newProfile.put("playlists", playlists);

        List<String> likedSongs = new ArrayList<>();
        newProfile.put("likedSongs", likedSongs);

        // افزودن پروفایل جدید به userProfiles
        userProfiles.put(username, newProfile);

        // چاپ userProfiles پس از افزودن پروفایل جدید برای بررسی
        System.out.println("User profiles after adding new user: " + gson.toJson(userProfiles));

        // ذخیره پروفایل‌ها در فایل
        saveUserProfiles();

        return "user registered successfully";
    }

    // -------------------- WEBSOCKET SERVER --------------------
    private static void startWebSocketServer() {
        WebSocketServer wsServer = new WebSocketServer(new InetSocketAddress(WEBSOCKET_PORT)) {
            @Override
            public void onOpen(WebSocket conn, ClientHandshake handshake) {
                System.out.println("WebSocket client connected: " + conn.getRemoteSocketAddress());
            }

            @Override
            public void onClose(WebSocket conn, int code, String reason, boolean remote) {
                System.out.println("WebSocket client disconnected: " + conn.getRemoteSocketAddress());
            }

            @Override
            public void onMessage(WebSocket conn, String message) {
                try {
                    Request request = gson.fromJson(message, Request.class);
                    String response;

                    if ("get_explore_songs".equals(request.getAction())) {
                        File folder = new File(SONGS_FOLDER);
                        File[] files = folder.listFiles((dir, name) -> name.toLowerCase().endsWith(".mp3"));

                        List<Map<String, Object>> songs = new ArrayList<>();

                        if (files != null) {
                            for (File file : files) {
                                String fileName = file.getName();
                                String id = fileName.replace(".mp3", "");
                                String title = id.replace("_", " ");

                                Map<String, Object> songData = new HashMap<>();
                                songData.put("id", id);
                                songData.put("title", Character.toUpperCase(title.charAt(0)) + title.substring(1));
                                songData.put("genre", "Unknown");

                                // برای Emulator اندروید
                                songData.put("url", "http://10.0.2.2:" + HTTP_PORT + "/songs/" + fileName);

                                songData.put("likes", songLikes.getOrDefault(id, 0));
                                songData.put("views", songViews.getOrDefault(id, 0));

                                songs.add(songData);
                            }
                        }
                        response = gson.toJson(songs);
                    } else {
                        response = "Invalid action";
                    }

                    conn.send(response);
                } catch (Exception e) {
                    System.out.println("WebSocket message handling error: " + e.getMessage());
                }
            }

            @Override
            public void onError(WebSocket conn, Exception ex) {
                System.out.println("WebSocket error: " + ex.getMessage());
            }

            @Override
            public void onStart() {
                System.out.println("WebSocket server started on port " + WEBSOCKET_PORT);
            }
        };

        wsServer.start();
    }

    // -------------------- DATA MODELS --------------------
    static class Request {
        private String action;
        private String payloadJson;

        public String getAction() {
            return action;
        }

        public String getPayloadJson() {
            return payloadJson;
        }
    }

    static class LoginRequest {
        private String username;
        private String password;

        public String getUsername() {
            return username;
        }

        public String getPassword() {
            return password;
        }
    }
}