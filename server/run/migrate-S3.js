(function() {
  var FilePicker, PeggParse, config, createThumbnail, exec, fetchImageUrls, fs, i, migrateImagesToS3, pp, request, storeImageFromUrl, updateFilename;

  fs = require('fs');

  PeggParse = require('./pegg-parse');

  FilePicker = require('node-filepicker');

  request = require('superagent');

  exec = require('child_process').exec;

  config = JSON.parse(fs.readFileSync(__dirname + "/../config.json", "utf-8"));

  for (i in config) {
    config[i] = process.env[i.toUpperCase()] || config[i];
  }

  console.log('---------------------');

  console.log('     MIGRATE S3      ');

  console.log('---------------------');

  console.log(config);

  console.log('---------------------');

  pp = new PeggParse(config);

  migrateImagesToS3 = function() {
    return fetchImageUrls(5, 0, [], function(items) {
      var filename, item, matches, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        matches = item.url.match(/[^\/]+(#|\?|$)/);
        filename = "_" + item.id + "." + matches[0];
        console.log("" + item.id + ", " + filename);
        _results.push(storeImageFromUrl(item.url, filename, "/full/" + filename, (function(_this) {
          return function(inkBlob) {
            inkBlob = JSON.parse(inkBlob);
            console.log(inkBlob);
            updateFilename(inkBlob.filename, item.id, function(res) {
              return console.log(res);
            });
            return createThumbnail(inkBlob, function(res) {
              return console.log(res);
            });
          };
        })(this)));
      }
      return _results;
    });
  };

  fetchImageUrls = function(limit, skip, urls, cb) {
    return pp.getRows('Choice', limit, skip, (function(_this) {
      return function(err, data) {
        var item, _i, _len, _ref;
        if (data.results.length > 0) {
          _ref = data.results;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            if (item.image !== "") {
              urls.push({
                id: item.objectId,
                url: item.image
              });
            }
          }
          return cb(urls);
        } else {
          return cb(urls);
        }
      };
    })(this));
  };

  storeImageFromUrl = function(url, filename, path, cb) {
    var command;
    command = "curl -X POST -d url='" + url + "' https://www.filepicker.io/api/store/S3?key=" + config.filepicker_api_key + "&filename=" + filename;
    console.log(command);
    return exec(command, function(error, stdout, stderr) {
      return cb(stdout);
    });
  };

  updateFilename = function(filename, id, cb) {
    return pp.updateRow('Choice', filename, id, function(err, data) {
      if (err != null) {
        return cb(err);
      } else {
        return cb(data);
      }
    });
  };

  createThumbnail = function(inkBlob, cb) {
    var filename, url;
    url = inkBlob.url + "/convert?format=jpg&w=100&h=100";
    filename = "_thumb_" + inkBlob.filename;
    return storeImageFromUrl(url, filename, "/thumbs/" + filename, function(res) {
      return cb(res);
    });
  };

  migrateImagesToS3();

}).call(this);
