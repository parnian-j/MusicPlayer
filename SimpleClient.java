import java.net.Socket;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;
import com.google.gson.Gson;

public class SimpleClient {

    public static void main(String[] args) {
        try (Socket socket = new Socket("localhost", 12345);
             PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
             BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
             Scanner scanner = new Scanner(System.in)) {

            Gson gson = new Gson();

            while (true) {
                System.out.println("Enter request (e.g., action=createPlaylist username=ali name=MyList isPrivate=true) or 'exit':");
                String inputLine = scanner.nextLine().trim();

                if (inputLine.equalsIgnoreCase("exit")) {
                    System.out.println("Exiting...");
                    break;
                }

                // مثال: action=createPlaylist username=ali name=MyList isPrivate=false
                String[] parts = inputLine.split("\\s+");
                String action = null;
                Map<String, String> payloadMap = new HashMap<>();

                for (String part : parts) {
                    if (part.startsWith("action=")) {
                        action = part.substring("action=".length());
                    } else if (part.contains("=")) {
                        String[] kv = part.split("=", 2);
                        if (kv.length == 2) {
                            payloadMap.put(kv[0], kv[1]);
                        }
                    }
                }

                if (action == null) {
                    System.out.println("Missing action. Use format: action=someAction key=value ...");
                    continue;
                }

                Request request = new Request();
                request.setAction(action);
                request.setPayloadJson(gson.toJson(payloadMap));

                String requestJson = gson.toJson(request);
                out.println(requestJson);
                System.out.println("Sent request: " + requestJson);

                String response = in.readLine();
                System.out.println("Response from server: " + response);
            }

        } catch (IOException e) {
            System.out.println("Error occurred: " + e.getMessage());
        }
    }
}




