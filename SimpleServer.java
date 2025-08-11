import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import com.google.gson.Gson;
import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class SimpleServer {

    private static final String HOST_IP = "192.168.1.9";
    private static final int HTTP_PORT = 8080;
    private static final int TCP_PORT = 12344;
    private static final int WEBSOCKET_PORT = 12345;
    private static final String SONGS_FOLDER = "server_songs";

    private static Map<String, Integer> songLikes = new HashMap<>();
    private static Map<String, Integer> songViews = new HashMap<>();

    private static Gson gson = new Gson();

    public static void main(String[] args) throws Exception {
        loadSongData();
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
                Request request = gson.fromJson(inputLine, Request.class);
                String response;

                switch (request.getAction()) {
                    case "login":
                        LoginRequest loginRequest = gson.fromJson(request.getPayloadJson(), LoginRequest.class);
                        response = UserManager.login(loginRequest.getUsername(), loginRequest.getPassword());
                        break;

                    case "signup":
                        Map<String, String> signupPayload = gson.fromJson(request.getPayloadJson(), Map.class);
                        String username = signupPayload.get("username");
                        String password = signupPayload.get("password");
                        String email = signupPayload.get("email");
                        String registerResult = UserManager.registerUser(username, password, email);

                        switch (registerResult) {
                            case "success":
                                response = "user registered successfully";
                                break;
                            case "name":
                                response = "username already taken";
                                break;
                            case "email":
                                response = "email already taken";
                                break;
                            default:
                                response = "unknown error";
                                break;
                        }
                        break;

                    case "like_song":
                        String songIdLike = request.getPayloadJson().replace("\"", "");
                        songLikes.put(songIdLike, songLikes.getOrDefault(songIdLike, 0) + 1);
                        saveSongData();
                        response = "success";
                        break;

                    case "increment_view":
                        String songIdView = request.getPayloadJson().replace("\"", "");
                        songViews.put(songIdView, songViews.getOrDefault(songIdView, 0) + 1);
                        saveSongData();
                        response = "success";
                        break;

                    default:
                        response = "Invalid action";
                }

                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                outputStream.flush();
            }

            socket.close();
        } catch (IOException e) {
            System.out.println("TCP client connection error: " + e.getMessage());
        }
    }

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
                System.out.println("Received from WebSocket client: " + message);
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

                                // آدرس برای Emulator (بجای localhost)
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