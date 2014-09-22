(function() {
  exports.setEnvironment = function(env) {
    console.log("set app environment: " + env);
    switch (env) {
      case "development":
        exports.DEBUG_LOG = true;
        exports.DEBUG_WARN = true;
        exports.DEBUG_ERROR = true;
        exports.DEBUG_CLIENT = true;
        exports.PARSE_APP_ID = 'zogf8qxK4ULBBRBn2EhYWwddyUczTDks9w56mNsr';
        return exports.PARSE_MASTER_KEY = '3ykoKuRAKk7zEBs4xejIfUqDmIxpOtaI5wyMH10R';
      case "testing":
        exports.DEBUG_LOG = true;
        exports.DEBUG_WARN = true;
        exports.DEBUG_ERROR = true;
        return exports.DEBUG_CLIENT = true;
      case "production":
        exports.DEBUG_LOG = false;
        exports.DEBUG_WARN = false;
        exports.DEBUG_ERROR = true;
        return exports.DEBUG_CLIENT = false;
      default:
        return console.log("environment " + env + " not found");
    }
  };

}).call(this);
