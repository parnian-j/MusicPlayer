import java.net.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
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

            // برای هر کلاینت یک ترد جدید می‌سازیم
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

                String response;

                if ("login".equals(request.getAction())) {
                    LoginRequest loginRequest = gson.fromJson(request.getPayloadJson(), LoginRequest.class);
                    response = UserManager.login(loginRequest.getUsername(), loginRequest.getPassword());

                } else if ("signup".equals(request.getAction())) {
                    Map<String, String> payloadMap = gson.fromJson(request.getPayloadJson(), Map.class);

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
                } else {
                    response = "Invalid action";
                }


                outputStream.write((response + "\n").getBytes(StandardCharsets.UTF_8));
                outputStream.flush();
            }

            System.out.println("Client disconnected: " + socket.getRemoteSocketAddress());
            socket.close();

        } catch (IOException e) {
            System.out.println("Connection error with client " + socket.getRemoteSocketAddress());
            e.printStackTrace();
        }
    }
}


