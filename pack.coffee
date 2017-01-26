# Pack images into a video file!
path = require 'path'
fs = require 'fs'
temp = require 'temp'
child_process = require 'child_process'
ffmpeg = require "./ffmpeg.js"

# Automatically remove temporary directory when tool is done
# temp.track()

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
# TODO: Rotating photos to conserve space resets frame count every time a new stream
# TODO: is selected. This occurrs every time the input size changes (ie a rotated photo)
archive = (root, metadata, options, callback)->
  if metadata.length
    # Create a temporary file to work in.
    temp.mkdir {dir: root}, (err, working)->
      return callback err if err

      # Discover orientation
      if metadata[0].width < metadata[0].height
        # Portrait
        rotate = (wid, hgt)->
          wid > hgt
      else
        # Landscape
        rotate = (wid, hgt)->
          wid < hgt

      # Gather intel
      max_width = 0
      max_height = 0
      padding = metadata.length.toString().length
      wait = metadata.length
      for data, i in metadata
        do (data, i)->
          # Add rotational info
          # data.rotate = rotate data.width, data.height

          # Collect the maximum size of our video
          if false #data.rotate
            max_width = Math.max max_width, data.height
            max_height = Math.max max_height, data.width
          else
            max_width = Math.max max_width, data.width
            max_height = Math.max max_height, data.height

          # Get index in string form!
          num_str = i.toString()

          # Rebuild paths
          o_path = path.join root, data.name
          w_path = path.join working, "0".repeat(padding - num_str.length) + num_str + ".jpg"

          fs.link o_path, w_path, (err)->
            return callback err if err

            wait -= 1
            if not wait # Continue!
              img_sequence = "%#{padding}d.jpg"
              options.cwd = working # Set our tempfile
              options.vfilter = [# Input our settings
                ffmpeg.pad max_width, max_height
                # ffmpeg.rotate 90, (i for m, i in metadata when m.rotate)
              ]
              pack_file = "pack.mp4"
              # Run compression
              ffmpeg.compress "%#{padding}d.jpg", pack_file, options, (err)->
                return callback err if err
                s_path = path.join dest
                fs.link
                console.log err
                console.log "DONE"

# TODO: Check output file for validation

# Pack images into a video file
module.exports = (src, dest, options = {}, callback)->
  options.crf = options.crf or 18 # Default quality value

  # Determine what we're using as a source.
  fs.stat src, (err, stats)->
    return callback err if err # Expecting "ENOENT" if not valid path
    if stats.isDirectory()
      # If a directory, collect files within.
      fs.readdir src, (err, files)->
        # Get full path names
        imgs = (f for f in (path.join(src, p) for p in files) when fs.statSync(f).isFile() and path.extname(f) in ALLOWED_EXT)
        gather_metadata imgs, (err, meta)->
          return callback err if err
          archive src, meta, options, (err)->
            callback err
    else if stats.isFile()
      if path.extname(src) in ALLOWED_EXT
        gather_metadata [src], (err, meta)->
          return callback err if err
          # Get the enclosing folder of the image
          root = path.dirname src
          archive root, meta, options, (err)->
            callback err
    else
      return callback new Error "Unrecognised input."
