request = window.superagent

class Admin
  resetUser: (userId, cb) =>
    request
      .get "/users/reset/#{userId}"
      .set('Accept', 'application/json')
      .end (res) ->
        res.json = (res.body)
        console.log res.json, res.status
        cb res if cb?

window.admin = new Admin

$(document).ready ->
  _resetUserSubmit = () =>
    # reset messsage
    $('#resetUser_message')
      .html("working ...")
      .parent()
        .removeClass('has-success')
        .removeClass('has-error')
    $('#resetUser_detail')
      .html("")

    # do the reset thing
    userId = $('#resetUser_id').val()
    window.admin.resetUser userId, (res) ->
      if res.status is 200
        $('#resetUser_message')
          .html(res.json.message)
          .parent().addClass('has-success')
        $('#resetUser_detail')
          .html JSON.stringify res.json.results
      else
        $('#resetUser_message')
          .html(res.json?.message or res.error)
          .parent().addClass('has-error')
        $('#resetUser_detail')
          .html JSON.stringify(res.json?.error or res.error)

  $('#resetUser').on 'submit', ->
    _resetUserSubmit()
    return false

