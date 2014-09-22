(function() {
  var app, config, env, express;

  express = require('express');

  app = express();

  app.port = process.env.PORT || process.env.VMC_APP_PORT || 3000;

  env = process.env.NODE_ENV || 'development';

  config = require('./config');

  config.setEnvironment(env);

  app.all('/list', function(req, res) {
    var list;
    list = require('./list');
    return list.serverScripts(res);
  });

  app.all('/getRows', function(req, res) {
    var parse;
    console.log(exports.DB_PORT);
    parse = require('./parse');
    return parse.getTable('Choice');
  });

  app.listen(app.port, function() {
    return console.log("Listening on " + app.port + "\nPress CTRL-C to stop server.");
  });

}).call(this);
