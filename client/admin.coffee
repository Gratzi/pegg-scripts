

# listen to actions from server
io = window.io.connect()

io.on 'update', (message) ->
  $('#resetUser_detail')
    .append "#{message}<br/>"

io.on 'done', (userId, results) ->
  $('#resetUser_message')
    .html "Success! User #{userId} is fresh like spring pheasant"
    .parent().addClass 'has-success'
  $('#resetUser_detail')
    .append "done!"

io.on 'error', (error) ->
  $('#resetUser_message')
    .html error.message
    .parent().addClass 'has-error'
  $('#resetUser_detail')
    .html JSON.stringify(error)

io.on 'message', (message) ->
  console.log "server says: ", message

# interact with the admin user interface
Admin = {
  resetUser: (userId) ->
    # reset messsage
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


# init the client app
$(document).ready ->
  $('#resetUser').on 'submit', ->
    Admin.resetUser $('#resetUser_id').val()
    return false

  io.emit 'ready'

