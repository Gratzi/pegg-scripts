

# listen to actions from server
io = window.io.connect()

io.on 'message', (data) ->
  $("##{data.taskName}_detail")
    .append "#{data.message}<br/>"

io.on 'done', (data) ->
  $("##{data.taskName}_message")
    .html data.message
    .parent().addClass 'has-success'
  $("##{data.taskName}_detail")
    .append "done!"

io.on 'error', (data) ->
  $("##{data.taskName}_message")
    .html data.error.message
    .parent().addClass 'has-error'
  $("##{data.taskName}_detail")
    .html JSON.stringify(data.error)

io.on 'message', (data) ->
  console.log "server says: ", data.message


# interact with the admin user interface
Admin = {
  deleteCard: (cardId) ->
    # reset messsage
    console.log "deleting card #{cardId}"
    $('#deleteCard_message')
      .html "working ..."
      .parent()
        .removeClass 'has-success'
        .removeClass 'has-error'
    $('#deleteCard_detail')
      .html ""

    # do the reset thing
    io.emit "deleteCard", cardId

  resetUser: (userId) ->
    # reset messsage
    console.log "resetting user #{userId}"
    $('#resetUser_message')
      .html "working ..."
      .parent()
        .removeClass 'has-success'
        .removeClass 'has-error'
    $('#resetUser_detail')
      .html ""

    # do the reset thing
    io.emit "resetUser", userId
}

window.Admin = Admin

# routing
hidePages = ->
  $(".page").hide()

window.onhashchange = hashChange = ->
  console.log "showing page #{window.location.hash}"
  hidePages()
  $(window.location.hash).show()

# init the app
$(document).ready ->
  $('#deleteCard').on 'submit', -> Admin.deleteCard $('#deleteCard_id').val(); false
  $('#resetUser').on  'submit', -> Admin.resetUser  $('#resetUser_id').val(); false
  if window.location.hash then hashChange()
  io.emit 'ready'

