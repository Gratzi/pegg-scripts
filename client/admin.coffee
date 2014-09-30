request = window.superagent

class Admin
  resetUser: (userId) =>
    'asdf'

window.admin = new Admin

$(document).ready ->
  $('#resetUser_submit').on 'click', ->
    userId = $('#resetUser_id').val()
    request
      .get "/users/reset/#{userId}"
      .end (res) ->
        console.log res
        return null
