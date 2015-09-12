#### Config file
# Sets application config parameters depending on `env` name
exports.setEnvironment = (env) ->
  console.log "set app environment: #{env}"
  switch(env)
    when "development"
      exports.DEBUG_LOG = true
      exports.DEBUG_WARN = true
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = true
      exports.PARSE_APP_ID = 'XXX'
      exports.PARSE_MASTER_KEY = 'XXX'
      exports.FILE_PICKER_ID = 'XXX'

    when "testing"
      exports.DEBUG_LOG = true
      exports.DEBUG_WARN = true
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = true
      exports.PARSE_APP_ID = 'XXX'
      exports.PARSE_MASTER_KEY = 'XXX'

    when "production"
      exports.DEBUG_LOG = false
      exports.DEBUG_WARN = false
      exports.DEBUG_ERROR = true
      exports.DEBUG_CLIENT = false
    else
      console.log "environment #{env} not found"
