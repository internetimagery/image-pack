(function() {
  var IMG_EXT, VID_EXT, ffmpeg, fs, ora, path, temp, zip,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  fs = require('fs-extra');

  temp = require('temp');

  path = require('path');

  ora = require('ora');

  ffmpeg = require("./ffmpeg.js");

  temp.track();

  IMG_EXT = [".jpg", ".jpeg"];

  VID_EXT = [".mp4"];

  zip = function() {
    var arr, i, j, length, lengthArray, ref, results;
    lengthArray = (function() {
      var j, len, results;
      results = [];
      for (j = 0, len = arguments.length; j < len; j++) {
        arr = arguments[j];
        results.push(arr.length);
      }
      return results;
    }).apply(this, arguments);
    length = Math.min.apply(Math, lengthArray);
    results = [];
    for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      results.push((function() {
        var l, len, results1;
        results1 = [];
        for (l = 0, len = arguments.length; l < len; l++) {
          arr = arguments[l];
          results1.push(arr[i]);
        }
        return results1;
      }).apply(this, arguments));
    }
    return results;
  };

  module.exports = function(src, dest, options, callback) {
    options.cwd = dest;
    return fs.stat(src, function(err, stat) {
      var ref;
      if (err) {
        return callback(err);
      }
      if (!stats.isFile() || (ref = path.extname(src).toLowerCase(), indexOf.call(VID_EXT, ref) < 0)) {
        return callback(new Error("Source needs to be a video of format: " + (VID_EXT.join())));
      }
      return fs.ensureDir(dest, function(err) {
        if (err) {
          return callback(err);
        }
        return ffmpeg.metadata(src, options, function(err, metadata) {
          var index_data, index_data_absolute, k, v;
          if (err) {
            return callback(err);
          }
          try {
            index_data = JSON.parse(metadata.comment);
            index_data_absolute = new function() {
              var k, v;
              for (k in index_data) {
                v = index_data[k];
                this[path.join(dest, k)] = v;
              }
              return this;
            };
            for (k in index_data_absolute) {
              v = index_data_absolute[k];
              if (fs.existsSync(k)) {
                return callback(new Error("File already exists: " + k));
              }
            }
            return temp.mkdir({
              dir: dest
            }, function(err, working) {
              if (err) {
                return callback(err);
              }
              options.cwd = working;
              return ffmpeg.extract(src, "%9d.bmp", options, function(err) {
                if (err) {
                  return callback(err);
                }
                return fs.readdir(working, function(err, files) {
                  var f, j, len, ref1, results, wait;
                  if (err) {
                    return callback(err);
                  }
                  wait = files.length;
                  ref1 = zip(files, (function() {
                    var results1;
                    results1 = [];
                    for (k in index_data_absolute) {
                      v = index_data_absolute[k];
                      results1.push(k);
                    }
                    return results1;
                  })());
                  results = [];
                  for (j = 0, len = ref1.length; j < len; j++) {
                    f = ref1[j];
                    results.push((function(f) {
                      return fs.ensureDir(path.dirname(f[1]), function(err) {
                        if (err) {
                          return callback(err);
                        }
                        options.vfilter = {
                          crop: {
                            w: index_data_absolute[f[1]][0],
                            h: index_data_absolute[f[1]][1],
                            x: 0,
                            y: 0
                          }
                        };
                        return ffmpeg.extract(f[0], f[1], options, function(err) {
                          if (err) {
                            return callback(err);
                          }
                          wait -= 1;
                          if (!wait) {
                            return callback(null);
                          }
                        });
                      });
                    })(f));
                  }
                  return results;
                });
              });
            });
          } catch (error) {
            err = error;
            if (err.name !== "SyntaxError") {
              return callback(err);
            }
            return ffmpeg.extract(src, "%9d.jpg", options, function(err) {
              return callback(err);
            });
          }
        });
      });
    });
  };

}).call(this);
