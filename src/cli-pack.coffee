# Pack files into movie files

ora = require 'ora'
path = require 'path'
program = require "commander"
data = require "../package.json"
pack = require "./pack"

error = (err)->
  console.error err.message
  process.exit 1

program.version data.version
       .description "Pack images into a video file, taking advantage of the higher compression for storage/distribution/archive."
       .option "-r --recursive", "Take images from subfolders as well as the provided one."
       .arguments "<source> <destination>"
       .action (source, destination)->
         source_path = path.resolve source
         dest_path = path.resolve destination
         options =
           recursive: program.recursive?
         spinner = ora("Packing images").start()
         pack source_path, dest_path, options, (err)->
           if err then spinner.fail() else spinner.succeed()
           error err if err
       .parse process.argv
