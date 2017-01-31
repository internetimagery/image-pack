(function() {
  var data, error, ora, path, program, unpack;

  ora = require('ora');

  path = require('path');

  program = require("commander");

  unpack = require("./unpack");

  data = require("../package.json");

  error = function(err) {
    console.error(err.message);
    return process.exit(1);
  };

  program.version(data.version).description("Pull images out of a video file. Recreate file names and directory structure if applicable.")["arguments"]("<source> <destination>").action(function(source, destination) {
    var dest_path, options, source_path, spinner;
    source_path = path.resolve(source);
    dest_path = path.resolve(destination);
    options = {};
    spinner = ora("Unpacking images").start();
    return unpack(source_path, dest_path, options, function(err) {
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
