
argparse = require 'argparse'
ffmpeg = require 'ffmpeg-static'




parser = new argparse.ArgumentParser
  version: "1.0.0"
  addHelp: true
  description: "Compress images into and out of a video."

parser.addArgument ["Method"], {help: "Pack / Unpack images.", choices:["pack", "unpack"]}
parser.addArgument ["Source"], {help: "Pack: Image or Folder of images. Unpack: Video."}
parser.addArgument ["Output"], {help: "Pack: Video file. Unpack: Empty folder."}


args = parser.parseArgs()
console.log args
