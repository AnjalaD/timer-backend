const string MESSEGE_SEPARATOR = "•••";

function  encodeMessage(SendingMessage message) returns string {
        return message.messageType + MESSEGE_SEPARATOR + message.message;
    }


function decodeMessage(string message) returns ReceivedMessage|error {
    string:RegExp r = re`${MESSEGE_SEPARATOR}`;
    string[] parts = r.split(message);

    ReceivedMessageType messageType = check parts[0].fromJsonWithType(ReceivedMessageType);
    string messageData = parts.length() > 1 ? parts[1] : "";

    return {
        messageType: messageType,
        message: messageData
    };
}