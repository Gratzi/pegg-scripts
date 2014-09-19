(function() {
  var Migrate;

  Parse.initialize("oBVGtJcA1YL8qAHtRHE1sm46edv3CdxSDCCBAyH3", "jOzfgxXTgD83QGnSyEcJgdCGEE4tNQz2bMEP4Zxe");

  Migrate = (function() {
    function Migrate() {}

    Migrate.prototype.migrate = function() {
      filepicker.setKey("A36NnDQaISmXZ8IOmKGEQz");
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

    Migrate.prototype.fetchImageUrls = function() {
      var Choice, card, choiceQuery;
      Choice = Parse.Object.extend('Choice');
      choiceQuery = new Parse.Query(Choice);
      card = new Parse.Object('Card');
      return choiceQuery.find({
        success: (function(_this) {
          return function(choices) {
            if ((choices != null ? choices.length : void 0) > 0) {
              return cb(choices);
            } else {
              return cb(null);
            }
          };
        })(this),
        error: function(error) {
          console.log("Error fetching choices: " + error.code + " " + error.message);
          return cb(null);
        }
      });
    };

    return Migrate;

  })();

  window.migrate = new Migrate();

}).call(this);
