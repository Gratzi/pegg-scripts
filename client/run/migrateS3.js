(function() {
  var Migrate;

  Parse.initialize("oBVGtJcA1YL8qAHtRHE1sm46edv3CdxSDCCBAyH3", "jOzfgxXTgD83QGnSyEcJgdCGEE4tNQz2bMEP4Zxe");

  filepicker.setKey("A36NnDQaISmXZ8IOmKGEQz");

  Migrate = (function() {
    function Migrate() {}

    Migrate.prototype.moveImagesToS3 = function() {
      return this.fetchImageUrls(5, 0, [], function(items) {
        var filename, item, matches, path, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = items.length; _i < _len; _i++) {
          item = items[_i];
          matches = item.url.match(/[^\/]+(#|\?|$)/);
          filename = "_" + item.id + "." + matches[0];
          path = '/full';
          _results.push(console.log(item));
        }
        return _results;
      });
    };

    Migrate.prototype.pickAndStore = function() {
      return filepicker.pickAndStore({
        mimetype: "image/*"
      }, {
        path: '/uploaded/'
      }, function(InkBlobs) {
        var result;
        result = InkBlobs[0];
        result.fullS3 = Config.s3.bucket + InkBlobs[0].key;
        return filepicker.convert(InkBlobs[0], {
          width: 100,
          height: 100,
          fit: 'clip',
          format: 'jpg'
        }, {
          path: '/processed/'
        }, (function(_this) {
          return function(thumbBlob) {
            thumbBlob.s3 = Config.s3.bucket + thumbBlob.key;
            return result.thumb = thumbBlob;
          };
        })(this));
      });
    };

    Migrate.prototype.fetchImageUrls = function(limit, skip, urls, cb) {
      var Choice, choiceQuery;
      Choice = Parse.Object.extend('Choice');
      choiceQuery = new Parse.Query(Choice);
      choiceQuery.limit(limit);
      choiceQuery.skip(skip);
      return choiceQuery.find({
        success: (function(_this) {
          return function(choices) {
            var choice, _i, _len;
            if ((choices != null ? choices.length : void 0) > 0) {
              for (_i = 0, _len = choices.length; _i < _len; _i++) {
                choice = choices[_i];
                urls.push({
                  id: choice.objectId,
                  url: choice.image
                });
              }
              return cb(urls);
            } else {
              return cb(urls);
            }
          };
        })(this),
        error: function(error) {
          console.log("Error fetching choices: " + error.code + " " + error.message);
          return cb(null);
        }
      });
    };

    Migrate.prototype.saveImagesToS3 = function(url, filename, path, cb) {};

    Migrate.prototype.saveUrlToParse = function(id, full, thumb, cb) {
      var choiceQuery;
      choiceQuery = new Parse.Query('Choice');
      choiceQuery.equalTo('objectId', id);
      return choiceQuery.first({
        success: (function(_this) {
          return function(result) {
            if (result != null) {
              result.set('plugFull', full);
              result.set('plugThumb', thumb);
              result.save();
              return cb("success");
            } else {
              return cb(null);
            }
          };
        })(this)
      });
    };

    return Migrate;

  })();

  window.migrate = new Migrate();

}).call(this);
