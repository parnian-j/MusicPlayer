import java.util.UUID;

public class UserManager {

        public static boolean registerUser(String username, String password, String email) {
            if (Database.getUserByUsername(username) != null) {
                return false; // user exists
            }
            User newUser = new User(UUID.randomUUID().toString(), username, password, email, false);
            Database.addUser(newUser);
            return true;
        }

        public static User login(String username, String password) {
            User user = Database.getUserByUsername(username);
            if (user != null && user.getPassword().equals(password)) {
                return user;
            }
            return null;
        }

        public static boolean changePassword(User user, String newPassword) {
            if (user != null) {
                user.setPassword(newPassword);
                return true;
            }
            return false;
        }

        public static boolean deleteUser(String username) {
            User user = Database.getUserByUsername(username);
            if (user != null) {
                Database.removeUser(username);
                return true;
            }
            return false;
        }
    }