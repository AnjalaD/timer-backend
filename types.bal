import ballerina/websocket;

type ControlMessageType "START" | "PAUSE";

type ReceivedMessageType  ControlMessageType | "CREATE_ROOM" | "JOIN_REMOTE" ;


type ReceivedMessage record {
    ReceivedMessageType messageType;
    string message;
};

type SendingMessageType ControlMessageType | "ROOM_CREATED" | "REMOTE_JOINED" | "REMOTE_LEFT" | "TIMER_LEFT";

type SendingMessage record {
    SendingMessageType messageType;
    string message;
};


type TimerRoom record {
    string roomId;
    websocket:Caller timer;
    websocket:Caller[] remotes;
};
