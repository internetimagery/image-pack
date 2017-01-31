(function() {
  var data, path, program;

  path = require('path');

  data = require("../package.json");

  program = require("commander");

  program.version(data.version).usage("[options] {pack|unpack} <source> <destination>").command("pack", "Pack images into a video file to compress/store them.").command("unpack", "Remove images from a video archive. Recreate image names and folder structure if possible.").parse(process.argv);

}).call(this);
