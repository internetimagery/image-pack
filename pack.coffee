# Pack images into a video file!
path = require 'path'
fs = require 'fs'
temp = require 'temp'
ffmpeg = require 'ffmpeg-static'
child_process = require 'child_process'

# Automatically remove temporary directory when tool is done
temp.track()

# Restrict us to jpegs for now
ALLOWED_EXT = [".jpg", ".jpeg"]

# Gather metadata from images
gather_metadata = (images, callback)->
  extract = /\d{2,}x\d{2,}/
  data = []
  i = images.length
  for img in images
    do (img)->
      child_process.execFile ffmpeg.path, ["-i", img], (err)->
        i -= 1
        meta = extract.exec err.message
        if meta?
          dimensions = meta[0].split "x"
          data.push {
            name: path.basename img
            width: dimensions[0]
            height: dimensions[1]
            rotate: if dimensions[1] > dimensions[0] then true else false
          }
          if i == 0 # We have checked everything
            # Sort the files in order
            callback null, data.sort (a, b)->
              a.name > b.name
        else
          return callback new Error "Bad file: #{img}"


# Link all files into a temp folder, using sequential naming
# run ffmpeg command to compress a video
archive = (root, metadata, callback)->
  # Create a temporary file to work in.
  temp.mkdir {dir: root}, (err, working)->
    return callback err if err

    # Gather intel
    max_width = 0
    max_height = 0
    padding = metadata.length.toString().length
    i = metadata.length
    for data, j in metadata
      do (data, j)->
        # Collect the maximum size of our video
        if data.rotate
          max_width = Math.max max_width, data.height
          max_height = Math.max max_height, data.width
        else
          max_width = Math.max max_width, data.width
          max_height = Math.max max_height, data.height

        # Get index in string form!
        num_str = j.toString()

        # Rebuild paths
        o_path = path.join root, data.name
        w_path = path.join working, "0".repeat(padding - num_str.length) + num_str + ".jpg"

        fs.link o_path, w_path, (err)->
          return callback err if err

          i -= 1
          if i == 0
            console.log "DONE"


      # o_path = path.join root, img.name
      # Link file!
  #
  # for img in images
  #   do (img)->
  #
  # index = 0
  # padding = images.length.toString().length



# Run ffmpeg command
# ffmpeg -i INPUT.jpg -crf 18 -c:v libx265 -vf pad="w=999:h=999" OUTPUT.mp4


# Pack images into a video file
module.exports = (src, dest, options, callback)->
  # options.crf = options.crf or 18 # Default quality value

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
          archive src, meta, (err)->
            callback err
    else if stats.isFile()
      if path.extname(src) in ALLOWED_EXT
        gather_metadata [src], (err, meta)->
          return callback err if err
          # Get the enclosing folder of the image
          root = path.dirname src
          archive root, meta, (err)->
            callback err
    else
      return callback new Error "Unrecognised input."
