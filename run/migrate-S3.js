(function() {
  var FilePicker, PeggParse, config, convertImage, fetchImageUrls, fetchRawImage, fp, fs, i, migrateImagesToS3, pp, pushToS3, request,
    __hasProp = {}.hasOwnProperty;

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
    return fetchImageUrls(0, [], function(urls) {
      var url, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = urls.length; _i < _len; _i++) {
        url = urls[_i];
        _results.push(fetchRawImage(url, function(image) {
          return pushToS3(image, function(inkBlob) {
            return console.log(inkBlob);
          });
        }));
      }
      return _results;
    });
  };

  fetchImageUrls = function(page, urls, cb) {
    return pp.getRows('Choice', {
      page: page,
      rows: 100
    }, function(err, data) {
      var d;
      if (data != null) {
        for (d in data) {
          if (!__hasProp.call(data, d)) continue;
          urls.push(d.image);
        }
        return fetchImageUrls(page + 1, urls.push(data, cb));
      } else {
        return cb(urls);
      }
    });
  };

  fetchRawImage = function(url, cb) {
    return request.get(url).end(function(err, res) {
      return cb(res);
    });
  };

  pushToS3 = function(image, cb) {
    return fp.store(payload, filename, mimetype, query, [callback]).then(function(inkBlob) {
      inkBlob = JSON.parse(inkBlob);
      return cb(inkBlob);
    });
  };

  convertImage = function(inkBlob) {
    return fp.convert(inkBlob);
  };

  migrateImagesToS3();

}).call(this);
