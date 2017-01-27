(function() {
  var ALLOWED_EXT, archive, child_process, ffmpeg, fs, gather_metadata, ora, path, temp,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  fs = require('fs');

  temp = require('temp');

  child_process = require('child_process');

  ora = require('ora');

  ffmpeg = require("./ffmpeg.js");

  temp.track();

  ALLOWED_EXT = [".jpg", ".jpeg"];

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
            return callback(null, data.sort(function(a, b) {
              return a.name > b.name;
            }));
          }
        });
      })(img));
    }
    return results;
  };

  archive = function(root, output, metadata, options, callback) {
    var concat, f;
    if (!metadata.length) {
      return callback(null);
    }
    concat = ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = metadata.length; i < len; i++) {
        f = metadata[i];
        results.push("file '" + f.name + "'");
      }
      return results;
    })()).join("\n");
    return temp.open({
      dir: root
    }, function(err, info) {
      if (err) {
        return callback(err);
      }
      return fs.writeFile(info.fd, concat, "utf8", function(err) {
        var data, i, index_path, len, max_height, max_width;
        if (err) {
          return callback(err);
        }
        max_width = 0;
        max_height = 0;
        for (i = 0, len = metadata.length; i < len; i++) {
          data = metadata[i];
          max_width = Math.max(max_width, data.width);
          max_height = Math.max(max_height, data.height);
        }
        index_path = output.substr(0, output.length - path.extname(output).length) + ".index";
        return fs.access(index_path, function(err) {
          if (!err) {
            return callback(new Error("Index file exists: " + (path.basename(index_path))));
          }
          if (err && err.code !== "ENOENT") {
            return callback(err);
          }
          return fs.writeFile(index_path, JSON.stringify(metadata, null, 2), function(err) {
            if (err) {
              return fs.unlink(index_path, function() {
                return callback(err);
              });
            }
            options.vfilter = [ffmpeg.pad(max_width, max_height)];
            options.cwd = root;
            options.comment = JSON.stringify(metadata);
            return ffmpeg.compress(info.path, output, options, function(err) {
              return callback(err);
            });
          });
        });
      });
    });
  };

  module.exports = function(src, dest, options, callback) {
    if (options == null) {
      options = {};
    }
    options.crf = options.crf || 18;
    if (path.extname(dest).toLowerCase() !== ".mp4") {
      return callback(new Error("Output needs to be an mp4 file"));
    }
    return fs.access(dest, function(err) {
      if (!err) {
        return callback(new Error("Destination file exists already."));
      }
      if (err && err.code !== "ENOENT") {
        return callback(err);
      }
      return fs.stat(src, function(err, stats) {
        var ref;
        if (err) {
          return callback(err);
        }
        if (stats.isDirectory()) {
          return fs.readdir(src, function(err, files) {
            var f, imgs, p;
            imgs = (function() {
              var i, len, ref, ref1, results;
              ref = (function() {
                var j, len, results1;
                results1 = [];
                for (j = 0, len = files.length; j < len; j++) {
                  p = files[j];
                  results1.push(path.join(src, p));
                }
                return results1;
              })();
              results = [];
              for (i = 0, len = ref.length; i < len; i++) {
                f = ref[i];
                if (fs.statSync(f).isFile() && (ref1 = path.extname(f).toLowerCase(), indexOf.call(ALLOWED_EXT, ref1) >= 0)) {
                  results.push(f);
                }
              }
              return results;
            })();
            return gather_metadata(imgs, function(err, meta) {
              var spinner;
              if (err) {
                return callback(err);
              }
              spinner = ora("Packing images.").start();
              return archive(src, dest, meta, options, function(err) {
                if (err) {
                  spinner.fail();
                } else {
                  spinner.succeed();
                }
                return callback(err);
              });
            });
          });
        } else if (stats.isFile()) {
          if (ref = path.extname(src).toLowerCase(), indexOf.call(ALLOWED_EXT, ref) >= 0) {
            return gather_metadata([src], function(err, meta) {
              var root, spinner;
              if (err) {
                return callback(err);
              }
              root = path.dirname(src);
              spinner = ora("Packing image.").start();
              return archive(root, dest, meta, options, function(err) {
                if (err) {
                  spinner.fail();
                } else {
                  spinner.succeed();
                }
                return callback(err);
              });
            });
          }
        } else {
          return callback(new Error("Unrecognised input."));
        }
      });
    });
  };

}).call(this);
