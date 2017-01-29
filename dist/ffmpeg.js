(function() {
  var child_process, dimensions_extract, ffmpeg, filter_generate, frame_expression, ini, path;

  ini = require('ini');

  path = require('path');

  ffmpeg = require("ffmpeg-static");

  child_process = require('child_process');

  filter_generate = function(filters) {
    var args, expression, key, name, val;
    if (!filters) {
      return [];
    }
    expression = ((function() {
      var results;
      results = [];
      for (name in filters) {
        args = filters[name];
        results.push(name + "='" + (((function() {
          var results1;
          results1 = [];
          for (key in args) {
            val = args[key];
            results1.push(key + "=" + val);
          }
          return results1;
        })()).join(":")) + "'");
      }
      return results;
    })()).join(",");
    return ["-vf", expression];
  };

  frame_expression = function(frames, command) {
    var f, frame_cmd, run_cmd;
    if (frames.length) {
      frame_cmd = ((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = frames.length; i < len; i++) {
          f = frames[i];
          results.push("eq(n," + f + ")");
        }
        return results;
      })()).join("+");
      run_cmd = ("if(" + frame_cmd + "," + command + ")").replace(/,/g, "\\,");
      return run_cmd;
    } else {
      return command.replace(/,/g, "\\,");
    }
  };

  module.exports.rotate = function(degrees, frames) {
    var rotate_cmd;
    rotate_cmd = degrees + "*PI/180";
    return "rotate='" + (frame_expression(frames || [], rotate_cmd)) + "'";
  };

  dimensions_extract = /\d{2,}x\d{2,}/;

  module.exports.dimensions = function(src, options, callback) {
    if (options == null) {
      options = {};
    }
    return child_process.execFile(ffmpeg.path, ["-i", src], {
      cwd: options.cwd || process.cwd()
    }, function(err) {
      var meta;
      meta = dimensions_extract.exec(err.message);
      if (meta != null) {
        return callback(null, meta[0].split("x"));
      }
      return callback(new Error("Bad file: " + src));
    });
  };

  module.exports.metadata = function(src, options, callback) {
    var command;
    if (options == null) {
      options = {};
    }
    command = ["-v", "error", "-i", src, "-f", "ffmetadata", "pipe:1"];
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err, stdout) {
      if (err) {
        return callback(err);
      }
      return callback(null, ini.parse(stdout));
    });
  };

  module.exports.compress = function(src, dest, options, callback) {
    var command, filters, input, metadata, opts, output;
    if (options == null) {
      options = {};
    }
    input = ["-y", "-f", "concat", "-safe", 0, "-i", src];
    filters = filter_generate(options.vfilter);
    opts = ["-crf", options.crf || 18, "-an", "-c:v", "libx265"];
    metadata = ["-metadata", "comment=" + options.metadata.comment];
    output = [dest];
    command = input.concat(filters.concat(opts.concat(metadata.concat(output))));
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err, stdout) {
      return callback(err);
    });
  };

  module.exports.extract = function(src, dest, options, callback) {
    var command, filters, input, output;
    if (options == null) {
      options = {};
    }
    input = ["-y", "-i", src];
    filters = filter_generate(options.vfilter);
    output = (function() {
      switch (path.extname(dest).toLowerCase()) {
        case ".jpg":
          return ["-qmin", 1, "-qmax", 1, "-qscale", 1, dest];
        case ".jpeg":
          return ["-qmin", 1, "-qmax", 1, "-qscale", 1, dest];
        default:
          return [dest];
      }
    })();
    command = input.concat(filters.concat(output));
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err, stdout) {
      return callback(err, stdout);
    });
  };

}).call(this);
