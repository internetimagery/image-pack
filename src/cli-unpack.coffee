# Pull images back out of movie file.

ora = require 'ora'
path = require 'path'
program = require "commander"
unpack = require "./unpack"
data = require "../package.json"

error = (err)->
  console.error err.message
  process.exit 1

program.version data.version
       .description "Pull images out of a video file. Recreate file names and directory structure if applicable."
       .arguments "<source> <destination>"
       .action (source, destination)->
         source_path = path.resolve source
         dest_path = path.resolve destination
         options = {}
         spinner = ora("Unpacking images").start()
         unpack source_path, dest_path, options, (err)->
           if err then spinner.fail() else spinner.succeed()
           error err if err
       .parse process.argv
