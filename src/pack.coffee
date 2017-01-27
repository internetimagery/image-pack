# Pack images into a video file!
path = require 'path'
fs = require 'fs'
temp = require 'temp'
child_process = require 'child_process'
ora = require 'ora'
ffmpeg = require "./ffmpeg.js"

# TODO: Rotating photos to conserve space resets frame count every time a new stream
# TODO: is selected. This occurrs every time the input size changes (ie a rotated photo)

# Automatically remove temporary directory when tool is done
temp.track()

# Restrict us to jpegs for now
ALLOWED_EXT = [".jpg", ".jpeg"]

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

# Link all files into a temp folder, using sequential naming
# run ffmpeg command to compress a video
archive = (root, output, metadata, options, callback)->
  return callback null if not metadata.length

  # make an index file of images
  concat = ("file '#{f.name}'" for f in metadata).join "\n"
  temp.open {dir: root}, (err, info)->
    return callback err if err
    fs.writeFile info.fd, concat, "utf8", (err)->
      return callback err if err

      # Discover orientation
      # if metadata[0].width < metadata[0].height
      #   # Portrait
      #   rotate = (wid, hgt)->
      #     wid > hgt
      # else
      #   # Landscape
      #   rotate = (wid, hgt)->
      #     wid < hgt

      # Gather intel
      max_width = 0
      max_height = 0
      for data in metadata
        # Add rotational info
        # data.rotate = rotate data.width, data.height

        # Collect the maximum size of our video
        # if data.rotate
        #   max_width = Math.max max_width, data.height
        #   max_height = Math.max max_height, data.width
        # else
          max_width = Math.max max_width, data.width
          max_height = Math.max max_height, data.height

      # Swap .mp4 with .index to make our index file
      index_path = output.substr(0, output.length - path.extname(output).length) + ".index"
      # Ensure index file doesn't already exist!
      fs.access index_path, (err)->
        return callback new Error "Index file exists: #{path.basename index_path}" if not err
        return callback err if err and err.code != "ENOENT"
        # Make the index file!
        fs.writeFile index_path, JSON.stringify(metadata, null, 2), (err)->
          if err # Problem? Cleanup!
            return fs.unlink index_path, ()->
              callback err

          # Set our video filters
          options.vfilter = [
            ffmpeg.pad max_width, max_height
            # ffmpeg.rotate 90, (i for m, i in metadata when m.rotate)
          ]
          options.cwd = root

          # Run compression
          ffmpeg.compress info.path, output, options, (err)->
            callback err

# Pack images into a video file
module.exports = (src, dest, options = {}, callback)->
  options.crf = options.crf or 18 # Default quality value

  # Quickly check our output file is accurate
  return callback new Error "Output needs to be an mp4 file" if path.extname(dest).toLowerCase() != ".mp4"

  # Check what we're using as an output.
  fs.access dest, (err)->
    return callback new Error "Destination file exists already." if not err
    return callback err if err and err.code != "ENOENT"

    # Determine what we're using as a source.
    fs.stat src, (err, stats)->
      return callback err if err # Expecting "ENOENT" if not valid path
      if stats.isDirectory()
        # If a directory, collect files within.
        fs.readdir src, (err, files)->
          # Get full path names
          imgs = (f for f in (path.join(src, p) for p in files) when fs.statSync(f).isFile() and path.extname(f).toLowerCase() in ALLOWED_EXT)
          gather_metadata imgs, (err, meta)->
            return callback err if err
            spinner = ora("Packing images.").start()
            archive src, dest, meta, options, (err)->
              if err then spinner.fail() else spinner.succeed()
              callback err
      else if stats.isFile()
        if path.extname(src).toLowerCase() in ALLOWED_EXT
          gather_metadata [src], (err, meta)->
            return callback err if err
            # Get the enclosing folder of the image
            root = path.dirname src
            spinner = ora("Packing image.").start()
            archive root, dest, meta, options, (err)->
              if err then spinner.fail() else spinner.succeed()
              callback err
      else
        return callback new Error "Unrecognised input."
