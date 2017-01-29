(function() {
  var argparse, args, cwd, data, ora, output, pack, parser, path, source, spinner, unpack;

  argparse = require('argparse');

  path = require('path');

  ora = require('ora');

  pack = require("./pack.js");

  unpack = require("./unpack.js");

  data = require("../package.json");

  parser = new argparse.ArgumentParser({
    version: data.version,
    addHelp: true,
    description: "Compress images into and out of a video."
  });

  parser.addArgument(["Method"], {
    type: "string",
    help: "Pack / Unpack images.",
    choices: ["pack", "unpack"]
  });

  parser.addArgument(["Source"], {
    type: "string",
    help: "Pack: Image or Folder of images. Unpack: Video."
  });

  parser.addArgument(["Output"], {
    type: "string",
    help: "Pack: Video file. Unpack: Empty folder."
  });

  parser.addArgument(["-q", "--quality"], {
    type: "int",
    help: "Quality of output. Lower number is higher quality."
  });

  parser.addArgument(["-r", "--recursive"], {
    action: "storeTrue",
    help: "Decend into subdirectories when collecting images to pack."
  });

  args = parser.parseArgs();

  cwd = process.cwd();

  source = path.resolve(cwd, args.Source);

  output = path.resolve(cwd, args.Output);

  switch (args.Method) {
    case "pack":
      spinner = ora("Packing images.");
      pack(source, output, {
        crf: args.quality,
        recursive: args.recursive
      }, function(err) {
        if (err) {
          spinner.fail();
        } else {
          spinner.succeed();
        }
        if (err) {
          return console.error(err);
        }
      });
      break;
    case "unpack":
      spinner = ora("Unpacking images.");
      unpack(source, output, {}, function(err) {
        if (err) {
          spinner.fail();
        } else {
          spinner.succeed();
        }
        if (err) {
          return console.error(err);
        }
      });
  }

}).call(this);
