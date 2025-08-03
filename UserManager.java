import java.io.*;
import java.lang.reflect.Type;
import java.util.HashMap;
import java.util.Map;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

public class UserManager {

    private static final Map<String, User> userMap = new HashMap<>();
    private static int userIdCounter = 1;
    private static final String USER_FILE = "users.json";
    private static final Gson gson = new Gson();

    public static Map<String, User> getUserMap() {
        return userMap;
    }

    public static String registerUser(String username, String password, String email) {
        if (userMap.containsKey(username)) {
            return "name";
        }
        for (User user : userMap.values()) {
            if (user.getEmail().equals(email)) {
                return "email";
            }
        }
        String userId = "user-" + userIdCounter++;
        User newUser = new User(userId, username, password, email, false);
        userMap.put(username, newUser);
        //saveUsersToFile();  // ذخیره تغییر بعد ثبت نام
        return "success";
    }

    public static String login(String username, String password) {
        User user = userMap.get(username);
        if (user == null) {
            return "invalid username or password";
        }

        if (user.getPassword().equals(password)) {
            return "welcome in " + user.getUsername();
        } else {
            return "wrong password";
        }
    }

    public static boolean changePassword(User user, String newPassword) {
        if (user != null && userMap.containsKey(user.getUsername())) {
            user.setPassword(newPassword);
            //saveUsersToFile();
            return true;
        }
        return false;
    }

    public static boolean deleteUser(String username) {
        if (userMap.containsKey(username)) {
            userMap.remove(username);
            //saveUsersToFile();
            return true;
        }
        return false;
    }

    public static User getUser(String username) {
        return userMap.get(username);
    }



    /*public static void loadUsersFromFile() {
        try (Reader reader = new FileReader(USER_FILE)) {
            Type type = new TypeToken<Map<String, User>>() {}.getType();
            Map<String, User> users = gson.fromJson(reader, type);
            if (users != null) {
                userMap.clear();
                userMap.putAll(users);

                userIdCounter = users.values().stream()
                        .map(User::getId)
                        .map(id -> id.replace("user-", ""))
                        .mapToInt(Integer::parseInt)
                        .max()
                        .orElse(0) + 1;
            }
        } catch (FileNotFoundException e) {
            System.out.println("User file not found, starting fresh.");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    public static void saveUsersToFile() {
        try (Writer writer = new FileWriter(USER_FILE)) {
            gson.toJson(userMap, writer);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }*/
}

