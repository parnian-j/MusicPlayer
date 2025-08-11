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
             BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
             Scanner scanner = new Scanner(System.in)) {

            Gson gson = new Gson();

            while (true) {
                System.out.println("Enter action (signup / login) or 'exit' to quit:");
                String action = scanner.nextLine().trim().toLowerCase();

                if (action.equals("exit")) {
                    System.out.println("Exiting...");
                    break;
                }

                if (!action.equals("signup") && !action.equals("login")) {
                    System.out.println("Invalid action. Please enter 'signup' or 'login'.");
                    continue;
                }

                Map<String, String> payloadMap = new HashMap<>();

                if (action.equals("signup")) {
                    System.out.print("Enter username: ");
                    String username = scanner.nextLine().trim();

                    System.out.print("Enter password: ");
                    String password = scanner.nextLine().trim();

                    System.out.print("Enter email: ");
                    String email = scanner.nextLine().trim();

                    payloadMap.put("username", username);
                    payloadMap.put("password", password);
                    payloadMap.put("email", email);

                }
                else if (action.equals("login")) {
                    System.out.print("Enter username: ");
                    String username = scanner.nextLine().trim();

                    System.out.print("Enter password: ");
                    String password = scanner.nextLine().trim();

                    payloadMap.put("username", username);
                    payloadMap.put("password", password);
                }

                Request request = new Request();
                request.setAction(action);
                request.setPayloadJson(gson.toJson(payloadMap));

                String requestJson = gson.toJson(request);
                out.println(requestJson);
                System.out.println("Sent request: " + requestJson);
                BufferedReader inait = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
                String response = inait.readLine();
                System.out.println("Response from server: " + response);


            }

        } catch (IOException e) {
            System.out.println("Error occurred: " + e.getMessage());

        }
    }
}



