(function() {
  var child_process, dimensions_extract, ffmpeg, frame_expression;

  ffmpeg = require("ffmpeg-static");

  child_process = require('child_process');

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

  module.exports.pad = function(width, height) {
    return "pad='w=" + width + ":h=" + height + "'";
  };

  dimensions_extract = /\d{2,}x\d{2,}/;

  module.exports.dimensions = function(src, callback) {
    return child_process.execFile(ffmpeg.path, ["-i", src], function(err) {
      var meta;
      meta = dimensions_extract.exec(err.message);
      if (meta != null) {
        return callback(null, meta[0].split("x"));
      }
      return callback(new Error("Bad file: " + img));
    });
  };

  module.exports.compress = function(src, dest, options, callback) {
    var command;
    if (options == null) {
      options = {};
    }
    command = ["-y", "-f", "concat", "-i", src, "-crf", options.crf || 18, "-an", "-vf", options.vfilter ? options.vfilter.join(",") : "null", "-c:v", "libx265", dest];
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err, stdout) {
      return callback(err);
    });
  };

  module.exports.extract = function(src, dest, options, callback) {
    var command;
    if (options == null) {
      options = {};
    }
    command = ["-y", "-i", src, dest];
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err, stdout) {
      return callback(err);
    });
  };

  module.exports.crop = function(src, dest, width, height, options, callback) {
    var command;
    if (options == null) {
      options = {};
    }
    command = ["-y", "-i", src, "-vf", "crop='" + width + ":" + height + ":0:0'", "-qmin", 1, "-qmax", 1, "-qscale", 1, dest];
    return child_process.execFile(ffmpeg.path, command, {
      cwd: options.cwd || process.cwd()
    }, function(err) {
      return callback(err);
    });
  };

}).call(this);
