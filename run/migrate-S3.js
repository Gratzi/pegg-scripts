(function() {
  var config, convertImage, fetchImageUrls, fs, http, loadConfig, pegg_parse;

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

  pegg_parse = require("./../lib/pegg-parse")(config);

  fetchImageUrls = function(err, res) {
    return pegg_parse.getRows('Choice', 20, function(data) {
      var row, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        row = data[_i];
        _results.push(convertImage(row.url));
      }
      return _results;
    });
  };

  convertImage = function(url) {
    filepicker.convert(url);
    return filepicker.save(inkblog);
  };

}).call(this);
