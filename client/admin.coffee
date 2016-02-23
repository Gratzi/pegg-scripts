log = -> console.log arguments...

class Client
  constructor: (@server) ->
    $('#card').on       'submit', @createOrUpdateCard
    $('#deleteCard').on 'submit', @deleteCard
    $('#resetUser').on  'submit', @resetUser
    $('#deleteUser').on 'submit', @deleteUser
    $('#script_migrateS3').on  'submit', @migrateS3
    $('#script_updateBesties').on  'submit', @updateBesties
    @server.io.on 'message', @onMessage
    @server.io.on 'done',    @onDone
    @server.io.on 'error',   @onError

  ### Actions ###

  createOrUpdateCard: (e) =>
    data = $('#card form').serializeObject()
    data.section = 'card'
    if data.cardId?
      log "upadating card:", data
      @do 'updateCard', data
    else
      log "creating card:", data
      @do 'createCard', data
    e.preventDefault()

  deleteCard: (e) =>
    cardId = $('#deleteCard input[name="cardId"]').val()
    log "deleting card #{cardId}"
    @do 'deleteCard',
      section: 'deleteCard'
      cardId: cardId
    e.preventDefault()

  deleteUser: (e) =>
    userId = $('#deleteUser input[name="userId"]').val()
    log "deleting user #{userId}"
    @do 'deleteUser',
      section: 'deleteUser'
      userId: userId
    e.preventDefault()

  resetUser: (e) =>
    userId = $('#resetUser input[name="userId"]').val()
    log "resetting user #{userId}"
    @do 'resetUser',
      section: 'resetUser'
      userId: userId
    e.preventDefault()

  migrateS3: (e) =>
    log "migrating image content to S3"
    @do 'migrateS3', section: 'scripts'
    e.preventDefault()

  updateBesties: (e) =>
    log "updating bestie scores"
    @do 'updateBesties', section: 'scripts'
    e.preventDefault()

  ### Server Listeners ###

  onMessage: (data) =>
    log "server: ", data.message

  onDone: (data) =>
    section = data.data.section
    $("##{section} .message")
      .html data.message
      .parent().addClass 'has-success'
    log "#{data.data.section} done!", data.data
    @resetForm section

  onError: (data) =>
    message = data?.error?.message or data?.error?.error ? 'Unknown error occurred'
    fullMessage = "ERROR: #{message} (see server output for details)"
    @error data.data.section, fullMessage

  ### Helpers ###

  error: (section, message) ->
    console.error message
    $("##{section} .message")
      .html message
      .parent()
        .addClass 'has-error'
        .removeClass 'has-success'

  do: (task, data) =>
    @resetStyles data.section
    @showWorkingMessage data.section
    try
      @server[task] data
    catch err
      @error data.section, err.message

  showWorkingMessage: (section) ->
    $("##{section} .message")
      .html "working ..."

  resetForm: (section) ->
    $("##{section} form").each ->
      @reset()

  resetStyles: (section) ->
    $("##{section} .message")
      .parent()
        .removeClass 'has-success'
        .removeClass 'has-error'

class ServerActions
  constructor: ->
    # listen to actions from server
    @io = window.io.connect()
    @io.emit 'ready'

  _validateCard: (data) ->
    # validate it and clean it up
    for choice, i in data.choices
      if _.isEmpty(choice.text) and _.isEmpty(choice.blob.meta.url)
        data.choices[i] = undefined
      else
        choice.blob.small = choice.blob.meta.url
        choice.blob.big = choice.blob.meta.url

    if _.isEmpty(data.question)
      throw new Error 'Please enter a question'

    data.choices = _.compact data.choices
    if data.choices.length < 2
      throw new Error 'Please enter 2+ choices'

  updateCard: (data) ->
    @_validateCard data
    @io.emit 'updateCard', data

  createCard: (data) ->
    @_validateCard data
    @io.emit 'createCard', data

  deleteCard: (data) ->
    @io.emit 'deleteCard', data

  resetUser: (data) ->
    @io.emit 'resetUser', data

  deleteUser: (data) ->
    @io.emit 'deleteUser', data

  migrateS3: (data) ->
    @io.emit 'migrateImagesToS3', data

  updateBesties: (data) ->
    @io.emit 'updateBesties', data

class App
  constructor: ->
    @server = new ServerActions
    @client = new Client @server
    @initRouting()

  initRouting: ->
    window.onhashchange = @hashChange
    if window.location.hash then @hashChange()

  hashChange: ->
    page = window.location.hash or '#home'
    log "showing page #{page}"
    $(".page").hide()
    $(page).show()

# init the app
$(document).ready -> window.App = new App()
