import java.util.HashMap;
import java.util.Map;

public class UserManager {

    private static final Map<String, User> userMap = new HashMap<>();
    private static int userIdCounter = 1;

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
            return true;
        }
        return false;
    }

    public static boolean deleteUser(String username) {
        if (userMap.containsKey(username)) {
            userMap.remove(username);
            return true;
        }
        return false;
    }

    public static User getUser(String username) {
        return userMap.get(username);
    }
}
