import java.net.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import com.google.gson.Gson;

public class SimpleServer {

    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(12345);
        System.out.println("Server started on port 12345");

        Gson gson = new Gson();

        while (true) {
            Socket socket = serverSocket.accept();
            System.out.println("Client connected: " + socket.getRemoteSocketAddress());


            new Thread(() -> handleClient(socket, gson)).start();
        }
    }

    private static void handleClient(Socket socket, Gson gson) {
        try {
            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            OutputStream outputStream = socket.getOutputStream();

            String inputLine;

            while ((inputLine = in.readLine()) != null) {

                Request request = gson.fromJson(inputLine, Request.class);

                System.out.println("Received request:");
                System.out.println("Action: " + request.getAction());
                System.out.println("Payload: " + request.getPayloadJson());
                Map<String, String> payloadMap = gson.fromJson(request.getPayloadJson(), Map.class);
                String response = "";

                if ("login".equals(request.getAction())) {
                    LoginRequest loginRequest = gson.fromJson(request.getPayloadJson(), LoginRequest.class);
                    response = UserManager.login(loginRequest.getUsername(), loginRequest.getPassword());

                }
                else if ("signup".equals(request.getAction())) {


                    String username = payloadMap.get("username");
                    String password = payloadMap.get("password");
                    String email = payloadMap.get("email");

                    String respons = UserManager.registerUser(username, password, email);

                    if ("success".equals(respons)) {
                        response = "user registered successfully";
                    } else if ("name".equals(respons)) {
                        response = "username already taken, please try again with different username or login";
                    } else if ("email".equals(respons)) {
                        response = "email already taken, please try again with different email or login";
                    } else {
                        response = "unknown error";
                    }
                }


                else if (request.getAction().equals("play")) {
                    String username = payloadMap.get("username");
                    String songIdStr = payloadMap.get("songId");

                    if (username == null || songIdStr == null) {
                        response = "Missing username or songId";
                    }
                    else {
                        try {
                            int songId = Integer.parseInt(songIdStr);  // تبدیل رشته به int

                            User user = UserManager.getUserMap().get(username);
                            if (user != null) {
                                Song song = Song.FindByID(songId);


                                if (song != null) {
                                    response = user.getRoot().play(song);  // فراخوانی play
                                }
                                else {
                                    response = "Song not found with ID: " + songId;
                                }
                            } else {
                                response = "User not found";
                            }
                        } catch (NumberFormatException e) {
                            response = "Invalid songId format";
                        }
                    }
                }
                else if (request.getAction().equals("pause")) {
                    String username = payloadMap.get("username");
                    User user = UserManager.getUserMap().get(username);
                    if (user != null) {
                        response = user.getRoot().pause();
                    } else {
                        response = "User not found.";
                    }
                }

                else if (request.getAction().equals("createPlaylist")) {
                    String username = payloadMap.get("username");
                    String name = payloadMap.get("name");
                    boolean isPrivate = Boolean.parseBoolean(payloadMap.get("isPrivate"));
                    User user = UserManager.getUserMap().get(username);
                    if (user != null) {
                        PlayList newPl = new PlayList(name, isPrivate);
                        user.addPlaylist(newPl);
                        response = "Playlist created ";
                    }
                    else {
                        response = "User not found";
                    }
                }
                else if (request.getAction().equals("addToPlaylist")) {
                    String username = payloadMap.get("username");
                    int playlistId = Integer.parseInt(payloadMap.get("playlistId"));
                    int songId = Integer.parseInt(payloadMap.get("songId"));

                    User user = UserManager.getUserMap().get(username);
                    PlayList playlist = PlayList.getPLayList(playlistId);
                    Song song = Song.FindByID(songId);

                    if (user != null && playlist != null && song != null) {
                        if (!playlist.getSongs().contains(song)) {
                            playlist.addSong(song);
                            response = "Song added to playlist";
                        }
                        else {
                            response = "Song already exists in playlist";
                        }
                    }
                    else {
                        response = "Invalid user, playlist, or song ID";
                    }
                }
                else if (request.getAction().equals("removeFromPlaylist")) {
                    String username = payloadMap.get("username");
                    int playlistId = Integer.parseInt(payloadMap.get("playlistId"));
                    int songId = Integer.parseInt(payloadMap.get("songId"));
                    User user = UserManager.getUserMap().get(username);
                    PlayList playlist = PlayList.getPLayList(playlistId);
                    Song song = Song.FindByID(songId);
                    if (user != null && playlist != null && song != null) {
                        if (playlist.getSongs().contains(song)) {
                            playlist.removeSong(song);
                            response = "Song removed from playlist";
                        }
                        else {
                            response = "Song not in playlist";
                        }
                    }
                    else {
                        response = "Invalid user, playlist, or song ID";
                    }
                }
                else if (request.getAction().equals("viewPlaylist")) {
                    int playlistId = Integer.parseInt(payloadMap.get("playlistId"));
                    PlayList playlist = PlayList.getPLayList(playlistId);

                    if (playlist != null) {
                        List<Song> songs = playlist.getSongs();
                        StringBuilder result = new StringBuilder();
                        for (Song s : songs) {
                            result.append("[").append(s.getId()).append("] ")
                                    .append(s.getTitle()).append(" - ")
                                    .append(s.getArtist()).append("\n");
                        }
                        response = result.toString();
                    } else {
                        response = "Playlist not found";
                    }
                }
                else if (request.getAction().equals("like")) {
                    String username = payloadMap.get("username");
                    int songId = Integer.parseInt(payloadMap.get("songId"));

                    User user = UserManager.getUserMap().get(username);
                    Song song = Song.FindByID(songId);
                    if (user != null && song != null) {
                        if (song.like(username)) {
                            user.likeSong(song);
                            response = "Song liked successfully.";
                        } else {
                            response = "You have already liked this song.";
                        }
                    } else {
                        response = "User or Song not found.";
                    }
                }
                else if (request.getAction().equals("unlike")) {
                    String username = payloadMap.get("username");
                    int songId = Integer.parseInt(payloadMap.get("songId"));

                    User user = UserManager.getUserMap().get(username);
                    Song song = Song.FindByID(songId);

                    if (user != null && song != null) {
                        if (song.unlike(username)) {
                            user.unlikeSong(song);
                            response = "Song unliked successfully.";
                        }
                        else {
                            response = "You haven't liked this song yet.";
                        }
                    }
                    else {
                        response = "User or Song not found.";
                    }
                }

                else if (request.getAction().equals("addnewsong")) {
                    String title = payloadMap.get("title");
                    String artist = payloadMap.get("artist");

                    if (title != null && artist != null) {
                        Song song = new Song(title, artist);
                        response = "Song added with ID: " + song.getId();
                    }
                    else {
                        response = "Missing title or artist";
                    }
                }





                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                outputStream.flush();

            }


            System.out.println("Client disconnected: " + socket.getRemoteSocketAddress());
            socket.close();

        }
        catch (IOException e) {
            System.out.println("Connection error with client " + socket.getRemoteSocketAddress());

        }
    }
}


