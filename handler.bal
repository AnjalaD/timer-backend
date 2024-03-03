import ballerina/io;
import ballerina/websocket;
import ballerina/uuid;

final map<TimerRoom> rooms = {};

class Handler {
    function handleCreateRoom(websocket:Caller caller) returns ()|error {
        TimerRoom room = self._createRoom(caller);

        rooms[room.roomId] = room;

        caller.setAttribute("roomId", room.roomId);
        caller.setAttribute("role", "timer");

        SendingMessage sendingMessage = {
            messageType: "ROOM_CREATED",
            message: room.roomId
        };

        io:println("Room created " + room.roomId);
        check caller->writeMessage(encodeMessage(sendingMessage));
    }

    function handleJoinRemote(websocket:Caller caller, string roomId) returns ()|error {
        io:println(rooms.keys(), roomId);
        TimerRoom? room = rooms[roomId];

        if (room == ()) {
            return error("Room not found");
        }

        room.remotes.push(caller);

        caller.setAttribute("roomId", roomId);
        caller.setAttribute("role", "remote");

        websocket:Caller timer = room.timer;
        SendingMessage sendingMessage = {
            messageType: "REMOTE_JOINED",
            message: room.roomId
        };
        string mesageStr = encodeMessage(sendingMessage);

        check timer->writeMessage(mesageStr);
        check caller->writeMessage(mesageStr);
    }

    function handleStart(websocket:Caller caller) returns ()|error {
        check self._ensureCallerIsRemote(caller);

        TimerRoom room = check self._getRoomFromCaller(caller);

        websocket:Caller timer = room.timer;
        check timer->writeMessage(encodeMessage({messageType: "START", message: ""}));
    }


    function handlePause(websocket:Caller caller) returns ()|error {
        check self._ensureCallerIsRemote(caller);

        TimerRoom room = check self._getRoomFromCaller(caller);

        websocket:Caller timer = room.timer;
        check timer->writeMessage(encodeMessage({messageType: "PAUSE", message: ""}));
    }

    function handleOnClose(websocket:Caller caller) returns ()|error {
        string role = check caller.getAttribute("role").ensureType(string);
        string roomId = check caller.getAttribute("roomId").ensureType(string);

        TimerRoom? room = rooms[roomId];
        if (room == ()) {
            return error("Room not found");
        }

        if(role == "remote") {
            websocket:Caller timer = room.timer;
            check timer->writeMessage(encodeMessage({messageType: "REMOTE_LEFT", message: ""}));
        } else {
            foreach websocket:Caller rem in room.remotes {
                check rem->writeMessage(encodeMessage({messageType: "TIMER_LEFT", message: ""}));
            }
            
            _ = rooms.removeIfHasKey(roomId);
        }
    }


    private function _createRoom(websocket:Caller timer) returns TimerRoom {
        return {
            roomId: uuid:createType4AsString(),
            timer: timer,
            remotes: []
        };
    }
    

    private function _getRoomFromCaller(websocket:Caller caller) returns TimerRoom|error {
        string roomId = check caller.getAttribute("roomId").ensureType(string);
        TimerRoom? room = rooms[roomId];

        if (room == ()) {
            return error("Room not found");
        }

        return room;
    }

    private function _ensureCallerIsRemote(websocket:Caller caller) returns ()|error {
        string role = check caller.getAttribute("role").ensureType(string);
        if (role != "remote") {
            return error("Caller is not a remote");
        }
    }
}
