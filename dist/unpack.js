(function() {
  var ffmpeg, fs, ora, path, temp, zip;

  fs = require('fs');

  temp = require('temp');

  path = require('path');

  ora = require('ora');

  ffmpeg = require("./ffmpeg.js");

  temp.track();

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
        var k, len, results1;
        results1 = [];
        for (k = 0, len = arguments.length; k < len; k++) {
          arr = arguments[k];
          results1.push(arr[i]);
        }
        return results1;
      }).apply(this, arguments));
    }
    return results;
  };

  module.exports = function(src, dest, options, callback) {
    ffmpeg.comments(src, options, function(err, metadata) {
      return callback(null);
    });
    return callback(null);
    return fs.stat(dest, function(err, stats) {
      if (err) {
        return callback(err);
      }
      if (!stats.isDirectory()) {
        return callback(new Error("Destination needs to be a directory."));
      }
      return temp.mkdir({
        dir: dest
      }, function(err, working) {
        var extract_notify, working_name;
        if (err) {
          return callback(err);
        }
        working_name = "%9d.bmp";
        options.cwd = working;
        extract_notify = ora("Extracting images").start();
        return ffmpeg.extract(src, working_name, options, function(err) {
          if (err) {
            extract_notify.fail();
          } else {
            extract_notify.succeed();
          }
          if (err) {
            return callback(err);
          }
          return fs.readdir(working, function(err, files) {
            var index_path;
            if (err) {
              return callback(err);
            }
            index_path = src.replace(path.extname(src), ".index");
            return fs.readFile(index_path, "utf8", function(err, data) {
              var f, index_data, j, k, len, len1, ref, results, results1;
              if (err && err.code !== "ENOENT") {
                return callback(err);
              }
              try {
                index_data = JSON.parse(data);
                options.cwd = working;
                ref = zip(files, index_data);
                results = [];
                for (j = 0, len = ref.length; j < len; j++) {
                  f = ref[j];
                  results.push((function(f) {
                    var spinner;
                    spinner = ora(f[1].name).start();
                    return ffmpeg.crop(f[0], path.join(dest, f[1].name), parseInt(f[1].width), parseInt(f[1].height), options, function(err) {
                      if (err) {
                        spinner.fail();
                      } else {
                        spinner.succeed();
                      }
                      return callback(err);
                    });
                  })(f));
                }
                return results;
              } catch (error) {
                err = error;
                if (err.name !== "SyntaxError") {
                  return callback(err);
                }
                results1 = [];
                for (k = 0, len1 = files.length; k < len1; k++) {
                  f = files[k];
                  results1.push(fs.link(path.join(working, f), path.join(dest, f), function(err) {
                    return callback(err);
                  }));
                }
                return results1;
              }
            });
          });
        });
      });
    });
  };

}).call(this);
