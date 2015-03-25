function addMessage(msg) {
  $("#chat-log").append("" + msg + "");
}
function send() {
  var text = $("#message").val();
  if (text == '') {
    addMessage("Please Enter a Message");
    return;
  }

  try {
    socket.send(text);
    addMessage("Sent: " + text)
  } catch(exception) {
    addMessage("Failed To Send")
  }

  $("#message").val('');
}

$('#message').keypress(function(event) {
  if (event.keyCode == '13') { send(); }
});

$("#disconnect").click(function() {
  socket.close()
});
