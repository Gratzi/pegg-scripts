(function() {
  var FilePicker, PeggParse, binaryParser, config, convertImage, fetchImageUrls, fetchRawImage, fp, fs, i, migrateImagesToS3, pp, pushToS3, request;

  fs = require('fs');

  PeggParse = require('./pegg-parse');

  FilePicker = require('node-filepicker');

  request = require('superagent');

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

  fp = new FilePicker(config.filepicker_api_key);

  migrateImagesToS3 = function() {
    return fetchImageUrls(5, 0, [], function(items) {
      var item, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _results.push(fetchRawImage(item.id, item.url, function(res) {
          var extension, filename, id, matches;
          if ((res != null) && (res.body != null)) {
            id = res.req._headers['id'];
            matches = res.header['content-type'].match(/[^\/]+$/);
            extension = matches[0];
            filename = "_" + id + "." + extension;
            console.log("" + id + ", " + filename + ", " + res.header['content-type'] + ", " + res.req._headers['url'] + ", " + res.header['content-length'] + ", " + res.body.data.length);
            return pushToS3(res.body.data, filename, res.header['content-type'], function(inkBlob) {
              return console.log(inkBlob);
            });
          }
        }));
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

  fetchRawImage = function(id, url, cb) {
    return request.get(url).set('id', id).set('url', url).buffer(true).parse(binaryParser).end(function(err, res) {
      if (err != null) {
        console.log(err);
        return cb(null);
      } else {
        return cb(res);
      }
    });
  };

  binaryParser = function(res, callback) {
    console.log("binaryParser ftw");
    res.setEncoding("binary");
    res.data = "";
    res.on("data", function(chunk) {
      console.log("got some data...");
      return res.data += chunk;
    });
    return res.on("end", function() {
      console.log("all #done");
      return callback(null, new Buffer(res.data, "binary"));
    });
  };

  pushToS3 = function(payload, filename, mimetype, cb) {
    return fp.store(payload, filename, mimetype, null, cb).then(function(inkBlob) {
      console.log(inkBlob);
      return cb(inkBlob);
    });
  };

  convertImage = function(inkBlob) {
    return fp.convert(inkBlob);
  };

  migrateImagesToS3();

}).call(this);
