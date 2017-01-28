# TODO: Add more file types. bmp, png at least. concat should handle them
# TODO: change file structure of metadata to put the filename as key, and height/width as array following
# TODO: add optional scale param for exporting images

# Pack images into a video file!
path = require 'path'
fs = require 'fs'
temp = require 'temp'
ora = require 'ora'
walk = require 'walk'
stringify = require 'json-stable-stringify'
ffmpeg = require "./ffmpeg.js"

# TODO: Rotating photos to conserve space resets frame count every time a new stream
# TODO: is selected. This occurrs every time the input size changes (ie a rotated photo)

# Automatically remove temporary directory when tool is done
temp.track()

# Allowed file types
IMG_EXT = [".jpg", ".jpeg"]
VID_EXT = [".mp4"]

# Gather metadata from images
gather_metadata = (images, callback)->
  data = []
  wait = images.length
  for img in images
    do (img)->
      ffmpeg.dimensions img, (err, dimensions)->
        if err
          callback err
        else
          data.push {
            name: path.basename img
            width: dimensions[0]
            height: dimensions[1]
          }
        wait -= 1
        if not wait # We have checked everything
          # Sort the files in order
          callback null, data.sort (a, b)->
            a.name > b.name

# Walk paths pulling out files
collect_files = (root, recursive, callback)->
  if recursive
    files = []
    walk.walk root
        .on "file", (root, stat, next)->
          files.push path.join root, stat.name
          next()
        .on "errors", (root, stats, next)->
          callback stats
        .on "end", ()->
          callback null, files
  else
    fs.readdir root, (err, files)->
      return callback err if err
      callback null, (path.join(root, f) for f in files when fs.statSync(path.join(root, f)).isFile())

# Pack images into a vid  eo file
module.exports = (src, dest, options = {}, callback)->
  options.cwd = src # Working from the source dir

  # Ensure src is a directory, and exists.
  # Ensure dest is a mp4 file, and does not exist.
  fs.stat src, (err, stats)->
    return callback err if err
    return callback new Error "Source needs to be a Directory." if not stats.isDirectory()
    return callback new Error "Destination already exists." if fs.existsSync dest
    return callback new Error "Destination needs to be a video file of format: " + VID_EXT.join " " if path.extname(dest).toLowerCase() not in VID_EXT

    # Grab all files from the directory source
    # Then shortlist them into relevant ones (with ext in IMG_EXT)
    # Finally make the paths relative
    collect_files src, options.recursive or false, (err, files)->
      return callback err if err
      photos = (path.relative(src, f) for f in files when path.extname(f).toLowerCase() in IMG_EXT)
      return callback null if not photos.length

      # Convert paths to forward slashes if on windows
      # Also remove drive letters if on windows
      photos = (p.replace /\\/g, "/" for p in photos)
      photos = (p.replace /^\w:/, "" for p in photos)

      # Grab image dimensions and store them in a format:
      # [{FILENAME: [WIDTH, HEIGHT]}]
      photo_metadata = {}
      wait = photos.length # Wait for processes
      for photo in photos
        do (photo)->
          ffmpeg.dimensions photo, options, (err, dimensions)->
            return callback err if err
            photo_metadata[photo] = dimensions

            wait -= 1
            if not wait # Continue

              # Create a temporary file to list files for concatenation
              # format: file path/to/file.jpg
              temp.open {dir: src, suffix: ".ffcat"}, (err, info)->
                return callback err if err
                concat_data = ("file #{p.replace /([^\w])/g, "\\$1"}" for p in photos).join("\n")
                fs.writeFile info.fd, concat_data, "utf8", (err)->
                  return callback err if err

                  # Store the metadata for insertion into video metadata
                  # Using node package to ensure the filenames remain in order
                  photo_metadata_json = stringify photo_metadata
                  options.metadata = {
                    comment: photo_metadata_json
                  }

                  # Get the dimensions to use for the video.
                  # Dimensions need to fit all images.
                  # Add our padding argument to set the final size to this.
                  max_dimensions = [0, 0]
                  max_dimensions = [Math.max(max_dimensions[0], d[0]), Math.max(max_dimensions[1], d[1])] for p, d of photo_metadata
                  options.vfilter = [
                    ffmpeg.pad max_dimensions[0], max_dimensions[1]
                  ]

                  # Archive our photos into a video! Off we go!
                  ffmpeg.compress info.path, dest, options, (err)->
                    callback err
                    # DONE!
