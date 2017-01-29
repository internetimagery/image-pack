(function() {
  var IMG_EXT, VID_EXT, collect_files, ffmpeg, fs, gather_metadata, ora, path, stringify, temp, walk,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  fs = require('fs-extra');

  temp = require('temp');

  ora = require('ora');

  walk = require('walk');

  stringify = require('json-stable-stringify');

  ffmpeg = require("./ffmpeg.js");

  temp.track();

  IMG_EXT = [".jpg", ".jpeg"];

  VID_EXT = [".mp4"];

  gather_metadata = function(images, callback) {
    var data, i, img, len, results, wait;
    data = [];
    wait = images.length;
    results = [];
    for (i = 0, len = images.length; i < len; i++) {
      img = images[i];
      results.push((function(img) {
        return ffmpeg.dimensions(img, function(err, dimensions) {
          if (err) {
            callback(err);
          } else {
            data.push({
              name: path.basename(img),
              width: dimensions[0],
              height: dimensions[1]
            });
          }
          wait -= 1;
          if (!wait) {
            return callback(null, data);
          }
        });
      })(img));
    }
    return results;
  };

  collect_files = function(root, recursive, callback) {
    var files;
    if (recursive) {
      files = [];
      return walk.walk(root).on("file", function(root, stat, next) {
        files.push(path.join(root, stat.name));
        return next();
      }).on("errors", function(root, stats, next) {
        return callback(stats);
      }).on("end", function() {
        return callback(null, files);
      });
    } else {
      return fs.readdir(root, function(err, files) {
        var f;
        if (err) {
          return callback(err);
        }
        return callback(null, (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = files.length; i < len; i++) {
            f = files[i];
            if (fs.statSync(path.join(root, f)).isFile()) {
              results.push(path.join(root, f));
            }
          }
          return results;
        })());
      });
    }
  };

  module.exports = function(src, dest, options, callback) {
    if (options == null) {
      options = {};
    }
    options.cwd = src;
    return fs.ensureDir(src, function(err) {
      var ref;
      if (err) {
        return callback(err);
      }
      if (fs.existsSync(dest)) {
        return callback(new Error("Destination already exists."));
      }
      if (ref = path.extname(dest).toLowerCase(), indexOf.call(VID_EXT, ref) < 0) {
        return callback(new Error("Destination needs to be a video file of format: " + VID_EXT.join(" ")));
      }
      return collect_files(src, options.recursive || false, function(err, files) {
        var f, i, len, p, photo, photo_metadata, photos, ref1, results, wait;
        if (err) {
          return callback(err);
        }
        photos = (function() {
          var i, len, ref1, results;
          results = [];
          for (i = 0, len = files.length; i < len; i++) {
            f = files[i];
            if (ref1 = path.extname(f).toLowerCase(), indexOf.call(IMG_EXT, ref1) >= 0) {
              results.push(path.relative(src, f));
            }
          }
          return results;
        })();
        if (!photos.length) {
          return callback(null);
        }
        photos = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = photos.length; i < len; i++) {
            p = photos[i];
            results.push(p.replace(/\\/g, "/"));
          }
          return results;
        })();
        photos = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = photos.length; i < len; i++) {
            p = photos[i];
            results.push(p.replace(/^\w:/, ""));
          }
          return results;
        })();
        photo_metadata = {};
        wait = photos.length;
        ref1 = photos.sort();
        results = [];
        for (i = 0, len = ref1.length; i < len; i++) {
          photo = ref1[i];
          results.push((function(photo) {
            return ffmpeg.dimensions(photo, options, function(err, dimensions) {
              if (err) {
                return callback(err);
              }
              photo_metadata[photo] = dimensions;
              wait -= 1;
              if (!wait) {
                return temp.open({
                  dir: src,
                  suffix: ".ffcat"
                }, function(err, info) {
                  var concat_data;
                  if (err) {
                    return callback(err);
                  }
                  concat_data = ((function() {
                    var j, len1, results1;
                    results1 = [];
                    for (j = 0, len1 = photos.length; j < len1; j++) {
                      p = photos[j];
                      results1.push("file " + (p.replace(/([^\w])/g, "\\$1")));
                    }
                    return results1;
                  })()).join("\n");
                  return fs.writeFile(info.fd, concat_data, "utf8", function(err) {
                    var d, max_dimensions, photo_metadata_json;
                    if (err) {
                      return callback(err);
                    }
                    photo_metadata_json = stringify(photo_metadata);
                    options.metadata = {
                      comment: photo_metadata_json
                    };
                    max_dimensions = [0, 0];
                    for (p in photo_metadata) {
                      d = photo_metadata[p];
                      max_dimensions = [Math.max(max_dimensions[0], d[0]), Math.max(max_dimensions[1], d[1])];
                    }
                    options.vfilter = {
                      pad: {
                        w: max_dimensions[0],
                        h: max_dimensions[1]
                      }
                    };
                    return ffmpeg.compress(info.path, dest, options, function(err) {
                      return callback(err);
                    });
                  });
                });
              }
            });
          })(photo));
        }
        return results;
      });
    });
  };

}).call(this);
