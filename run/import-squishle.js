(function() {
  var PeggParse, config, fs, http, i, importFeeds, pp;

  http = require('http');

  fs = require('fs');

  PeggParse = require('./pegg-parse');

  config = JSON.parse(fs.readFileSync(__dirname + "/../config.json", "utf-8"));

  for (i in config) {
    config[i] = process.env[i.toUpperCase()] || config[i];
  }

  console.log('---------------------');

  console.log('   IMPORT SQUISHLE   ');

  console.log('---------------------');

  console.log(config);

  console.log('---------------------');

  pp = new PeggParse(config);

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
          return pp.insertCard(feeds[index], function(err, data) {
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
