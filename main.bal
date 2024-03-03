import ballerina/io;
import ballerina/websocket;

service /timer on new websocket:Listener(9090) {

    resource function get .() returns websocket:Service {
        // Accept the WebSocket upgrade by returning a `websocket:Service`.
        return new ChatService();
    }
}

service class ChatService {
    *websocket:Service;

    // This `remote function` is triggered when a new client connects to the service.
    // The `caller` object is the WebSocket connection of the client.
    remote function onOpen(websocket:Caller caller) returns error? {
        io:println("New client connected");
    }

    // This `remote function` is triggered when a new message is received
    // from a client. It accepts `anydata` as the function argument. The received data 
    // will be converted to the data type stated as the function argument.
    remote function onMessage(websocket:Caller caller, string chatMessage) returns error? {
        io:println(chatMessage);
        ReceivedMessage message = check decodeMessage(chatMessage);
        io:println(message.messageType, message.message);

        Handler handler = new Handler();
        
        match message.messageType {
            "CREATE_ROOM" => {
                return handler.handleCreateRoom(caller);
            }
            "JOIN_REMOTE" => {
                return handler.handleJoinRemote(caller, message.message);
            }
            "START" => {
                return handler.handleStart(caller);
            }
            "PAUSE" => {
                return handler.handlePause(caller);
            }
            _ => {
                return error("Invalid message type");
            }
        }
    }

    // This `remote function` is triggered when a client disconnects from the service.
    remote function onClose(websocket:Caller caller) returns error? {
        io:println(`Client disconnected ${caller.getAttribute("role")} ${caller.getAttribute("roomId")}`);

        Handler handler = new Handler();
        return handler.handleOnClose(caller);
    }

    // This `remote function` is triggered when an error occurs in the WebSocket connection.
    remote function onError(websocket:Caller caller, error e) {
        io:println("Error occurred: " + e.message());
    }
}


