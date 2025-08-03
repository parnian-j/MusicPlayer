public class Request {
    private String action;
    private String payloadJson;


    public Request(String action, String payloadJson) {
        this.action = action;
        this.payloadJson = payloadJson;
    }

    public Request() {
    }


    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getPayloadJson() { return payloadJson; }
    public void setPayloadJson(String payloadJson) { this.payloadJson = payloadJson; }
}
