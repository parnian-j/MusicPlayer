import java.util.LinkedList;
import java.util.Stack;

public class MusicPlayer {
    private LinkedList<Song> playList; // صف آهنگ‌ها
    private Stack<Song> historyStack;  // تاریخچه آهنگ‌های قبلی
    private Song currentSong;
    private boolean isPlaying;
    private int currentPosition;
    private User currentUser;


    public MusicPlayer(User user) {
        this.playList = new LinkedList<>();
        this.historyStack = new Stack<>();
        this.currentSong = null;
        this.isPlaying = false;
        this.currentPosition = 0;
        this.currentUser = user;
    }

    // افزودن آهنگ به لیست
    public void addToPlaylist(Song song) {
        playList.add(song);
    }


    public String play(Song song) {
        if (song == null) {
            return "choose song";
        }
        song.addPlayedCount();
        isPlaying = true;
        currentSong = song;
        currentPosition = 0;
        return "playing " + currentSong.getTitle();


    }
    public String play() {
        if (currentSong == null ){
            if (playList.isEmpty()){
                return "choose song";
            }
            else {
                currentSong = playList.getFirst();
                 return this.play(currentSong);
            }
        }
        else {
            isPlaying = true;
            currentPosition = 0;
            return "playing " + currentSong.getTitle();
        }
    }


    public String pause() {
        if (isPlaying) {
            isPlaying = false;
            return "Paused at playing " + currentSong.getTitle();
        }
        else{
            return "No music playing.";
        }
    }


    public void stop() {
        if (currentSong != null) {
            System.out.println("Stopped: " + currentSong.getTitle());
            currentSong = null;
            currentPosition = 0;
            isPlaying = false;
        }
    }


    public void next() {
        if (currentSong != null) {
            historyStack.push(currentSong);
        }
        currentSong = playList.poll();
        currentPosition = 0;

        if (currentSong != null) {
            isPlaying = true;
            System.out.println("Next song: " + currentSong.getTitle());
        } else {
            System.out.println("No more songs in playlist.");
            isPlaying = false;
        }
    }


    public void previous() {
        if (!historyStack.isEmpty()) {
            if (currentSong != null) {
                playList.addFirst(currentSong);
            }
            currentSong = historyStack.pop();
            currentPosition = 0;
            isPlaying = true;
            System.out.println("Playing previous song: " + currentSong.getTitle());
        } else {
            System.out.println("No previous song available.");
        }
    }

    public void rewind(int seconds) {
        if (currentSong != null) {
            currentPosition = Math.max(0, currentPosition - seconds);
            System.out.println("Rewound to " + currentPosition + "s");
        }
    }

    public void fastForward(int seconds) {
        if (currentSong != null) {
            currentPosition += seconds;
            if (currentPosition >= currentSong.getDuration()) {
                System.out.println("Reached end of song.");
                next();
            } else {
                System.out.println("Fast-forwarded to " + currentPosition + "s");
            }
        }
    }

    // Getters
    public Song getCurrentSong() { return currentSong; }
    public boolean isPlaying() { return isPlaying; }
    public int getCurrentPosition() { return currentPosition; }
}