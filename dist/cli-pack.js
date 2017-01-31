(function() {
  var data, error, ora, pack, path, program;

  ora = require('ora');

  path = require('path');

  program = require("commander");

  data = require("../package.json");

  pack = require("./pack");

  error = function(err) {
    console.error(err.message);
    return process.exit(1);
  };

  program.version(data.version).description("Pack images into a video file, taking advantage of the higher compression for storage/distribution/archive.").option("-r --recursive", "Take images from subfolders as well as the provided one.")["arguments"]("<source> <destination>").action(function(source, destination) {
    var dest_path, options, source_path, spinner;
    source_path = path.resolve(source);
    dest_path = path.resolve(destination);
    options = {
      recursive: program.recursive != null
    };
    spinner = ora("Packing images").start();
    return pack(source_path, dest_path, options, function(err) {
      if (err) {
        spinner.fail();
      } else {
        spinner.succeed();
      }
      if (err) {
        return error(err);
      }
    });
  }).parse(process.argv);

}).call(this);
