# Pack images into a video file!

fs = require 'fs-extra'
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
  fs.stat src, (err, stats)->
    return callback err if err
    return callback new Error "Source needs to be a video of format: #{VID_EXT.join()}" if not stats.isFile() or path.extname(src).toLowerCase() not in VID_EXT
    fs.ensureDir dest, (err)->
      return callback err if err

      # Attempt to get metadata.
      # If we have metadata, then extract frames into a temp folder in lossless bmp format, then crop into original structure
      # If we don't have metadata. Damn. Got nothing to go off, so just pull frames out in a sequence.
      ffmpeg.metadata src, options, (err, metadata)->
        return callback err if err
        try
          # Collect metadata and rebuild paths
          index_data = JSON.parse metadata.comment
          index_data_absolute = new ->
            @[path.join dest, k] = v for k, v of index_data
            this

          # Check paths are all free to use. Don't want to override anything.
          for k, v of index_data_absolute
            return callback new Error "File already exists: #{k}" if fs.existsSync k

          # Extract all frames into a temporary working space in bmp format
          # to ensure we aren't double encoding.
          # Then take those images, and crop them into their final locations.
          # TODO: Is it possible to crop each frame differently? Skipping this step and the large memory cost associated.
          # ffmpeg seems to only check the crop at the beginning of the video.
          temp.mkdir {dir:dest}, (err, working)->
            return callback err if err

            # Moving to our temp folder to work with
            options.cwd = working
            ffmpeg.extract src, "%9d.bmp", options, (err)->
              return callback err if err
              fs.readdir working, (err, files)->
                return callback err if err

                wait = files.length
                for f in zip files, (k for k, v of index_data_absolute)
                  do (f)->
                    fs.ensureDir path.dirname(f[1]), (err)->
                      return callback err if err
                      options.vfilter =
                        crop:
                          w: index_data_absolute[f[1]][0]
                          h: index_data_absolute[f[1]][1]
                          x: 0
                          y: 0

                      ffmpeg.extract f[0], f[1], options, (err)->
                        return callback err if err
                        wait -= 1
                        if not wait # continue
                          callback null
        catch err
          return callback err if err.name != "SyntaxError"

          # We have no metadata. Nothing we can do but just extract the frames in a numbered sequence.
          ffmpeg.extract src, "%9d.jpg", options, (err)->
            return callback err
            # DONE!
