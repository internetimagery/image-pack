# Pack images into a video file!

fs = require 'fs'
temp = require 'temp'
path = require 'path'
ora = require 'ora'
ffmpeg = require "./ffmpeg.js"

# Auto delete tempfile
temp.track()

IMG_EXT = [".jpg", ".jpeg"]
VID_EXT = [".mp4"]

# https://coffeescript-cookbook.github.io/chapters/arrays/zip-function
# Usage: zip(arr1, arr2, arr3, ...)
zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments


# Pack images into a video file
module.exports = (src, dest, options, callback)->
  options.cwd = dest # Working in the destination directory

  # Check our destination is a folder, and exists.
  # Check source exists also and is allowed format.
  fs.stat dest, (err, stats)->
    return callback err if err
    return callback new Error "Destination needs to be a directory" if not stats.isDirectory()
    return callback new Error "Source needs to be a video of format: " + VID_EXT.join " " if path.extname(src).toLowerCase() not in VID_EXT

    # Attempt to get metadata.
    # If we have metadata, then extract frames into a temp folder in lossless bmp format, then crop into original structure
    # If we don't have metadata. Damn. Got nothing to go off, so just pull frames out in a sequence.
    ffmpeg.metadata src, options, (err, metadata)->
      return callback err if err
      try
        index_data = JSON.parse metadata.comment
      catch err
        return callback err if err.name != "SyntaxError"

        # We have no metadata. Nothing we can do but just extract the frames in a numbered sequence.
        ffmpeg.extract src, "%9d.jpg", options, (err)->
          return callback err if err
          console.log "done"




  return



  # Ensure destination is a folder
  fs.stat dest, (err, stats)->
    return callback err if err
    return callback new Error "Destination needs to be a directory." if not stats.isDirectory()

    # Create a temporary file to work in
    temp.mkdir {dir: dest}, (err, working)->
      return callback err if err

      # Extract images into the tempfile
      working_name = "%9d.bmp"
      options.cwd = working
      extract_notify = ora("Extracting images").start()
      ffmpeg.extract src, working_name, options, (err)->
        if err then extract_notify.fail() else extract_notify.succeed()
        return callback err if err

        # Get our list of files
        fs.readdir working, (err, files)->
          return callback err if err

          # Read in index file (file of the same name with index suffix)
          index_path = src.replace path.extname(src), ".index"
          fs.readFile index_path, "utf8", (err, data)->
            return callback err if err and err.code != "ENOENT"
            try
              # Load our index file
              index_data = JSON.parse data
              options.cwd = working
              for f in zip files, index_data
                do (f)->
                  spinner = ora(f[1].name).start()
                  ffmpeg.crop f[0], path.join(dest, f[1].name), parseInt(f[1].width), parseInt(f[1].height), options, (err)->
                    if err then spinner.fail() else spinner.succeed()
                    callback err
            catch err
              return callback err if err.name != "SyntaxError"
              # We don't have an index file... continue without
              for f in files
                fs.link path.join(working, f), path.join(dest, f), (err)->
                  callback err
