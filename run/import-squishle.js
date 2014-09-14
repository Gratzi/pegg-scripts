(function() {
  var config, fs, http, importFeeds, loadConfig, parse_api;

  http = require('http');

  fs = require('fs');

  loadConfig = function() {
    var config, i;
    config = JSON.parse(fs.readFileSync(__dirname + "/../config.json", "utf-8"));
    for (i in config) {
      config[i] = process.env[i.toUpperCase()] || config[i];
    }
    console.log("Configuration");
    console.log(config);
    return config;
  };

  config = loadConfig();

  parse_api = require("./pegg-parse")(config);

  importFeeds = function(err, res) {
    return http.get(config.squishle_feed_url, function(res) {
      var body;
      body = "";
      res.on("data", function(chunk) {
        body += chunk;
      });
      return res.on("end", function() {
        var feeds, handleFeed;
        feeds = JSON.parse(body).sets;
        handleFeed = function(index) {
          return parse_api.insertCard(feeds[index], function(err, data) {
            if (err) {
              return console.log(err);
            } else {
              console.log(index);
              if (index < feeds.length - 1) {
                return handleFeed(index + 1);
              } else {
                return console.log(data);
              }
            }
          });
        };
        return handleFeed(0);
      });
    });
  };

  importFeeds();

}).call(this);
