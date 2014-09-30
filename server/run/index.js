(function() {
  var app, assets, config, env, express, peggParse, pp;

  express = require('express');

  peggParse = require('./peggParse');

  assets = require('connect-assets');

  app = express();

  app.port = process.env.PORT || process.env.VMC_APP_PORT || 3000;

  env = process.env.NODE_ENV || 'development';

  config = require('./config');

  config.setEnvironment(env);

  app.use(assets());

  app.use(express["static"](process.cwd() + '/client'));

  pp = new peggParse(config.PARSE_APP_ID, config.PARSE_MASTER_KEY);

  app.all('/', function(req, res) {
    return res.render('index');
  });

  app.all('/scripts', function(req, res) {
    var list;
    list = require('./list');
    return list.serverScripts(res);
  });

  app.all('/choices', function(req, res) {
    return pp.getTable('Choice', (function(_this) {
      return function(data) {
        return res.send(data);
      };
    })(this));
  });

  app.all('/users/reset/:id', function(req, res) {
    return pp.resetUser(req.params.id, (function(_this) {
      return function(result) {
        return res.send(result);
      };
    })(this));
  });

  app.listen(app.port, function() {
    return console.log("Listening on " + app.port + "\nPress CTRL-C to stop server.");
  });

}).call(this);
