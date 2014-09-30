(function() {
  var app, assets, bodyParser, config, env, express, peggParse, pp;

  express = require('express');

  peggParse = require('./peggParse');

  assets = require('connect-assets');

  bodyParser = require('body-parser');

  app = express();

  app.port = process.env.PORT || process.env.VMC_APP_PORT || 3000;

  env = process.env.NODE_ENV || 'development';

  config = require('./config');

  config.setEnvironment(env);

  app.use(bodyParser.json());

  app.use(assets());

  app.use(express["static"](process.cwd() + '/client'));

  pp = new peggParse(config.PARSE_APP_ID, config.PARSE_MASTER_KEY);

  app.all('/', function(req, res) {
    return res.render('index');
  });

  app.get('/scripts', function(req, res) {
    var list;
    list = require('./list');
    return list.serverScripts(res);
  });

  app.get('/choices', function(req, res) {
    return pp.getTable('Choice', (function(_this) {
      return function(data) {
        return res.send(data);
      };
    })(this));
  });

  app.post('/choice', function(req, res) {
    return pp.updateRow('Choice', req.body.id, {
      plug: req.body.orig,
      plugThumb: req.body.thumb
    }, (function(_this) {
      return function(data) {
        return res.send(data);
      };
    })(this));
  });

  app.all('/users/reset/:id', function(req, res) {
    console.log("reset user " + req.params.id);
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
