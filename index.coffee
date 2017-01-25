
argparse = require 'argparse'
ffmpeg = require 'ffmpeg-static'

# Pack images into a video file
pack = (src, dest, crf)->
  crf = crf or 18 # Default quality value
  console.log src, dest

# Retrieve images from a video
unpack = (src, dest)->
  console.log src, dest

parser = new argparse.ArgumentParser
  version: "1.0.0"
  addHelp: true
  description: "Compress images into and out of a video."

parser.addArgument ["Method"], {type:"string" ,help: "Pack / Unpack images.", choices:["pack", "unpack"]}
parser.addArgument ["Source"], {type:"string" ,help: "Pack: Image or Folder of images. Unpack: Video."}
parser.addArgument ["Output"], {type:"string" ,help: "Pack: Video file. Unpack: Empty folder."}
parser.addArgument ["-q", "--quality"], {type:"int" ,help: "Quality of output. Lower number is higher quality."}


args = parser.parseArgs()
console.log args.Method
console.log args
