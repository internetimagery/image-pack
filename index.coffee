
argparse = require 'argparse'
pack = require "./pack.js"
unpack = require "./unpack.js"

parser = new argparse.ArgumentParser
  version: "1.0.0"
  addHelp: true
  description: "Compress images into and out of a video."

parser.addArgument ["Method"], {type:"string", help: "Pack / Unpack images.", choices:["pack", "unpack"]}
parser.addArgument ["Source"], {type:"string", help: "Pack: Image or Folder of images. Unpack: Video."}
parser.addArgument ["Output"], {type:"string", help: "Pack: Video file. Unpack: Empty folder."}
parser.addArgument ["-q", "--quality"], {type:"int", help: "Quality of output. Lower number is higher quality."}

args = parser.parseArgs()
switch args.Method
  when "pack" then pack args.Source, args.Output, args.quality, (err)->
    console.error err if err
  when "unpack" then unpack args.Source, args.Output, args.quality, (err)->
    console.error err if err
