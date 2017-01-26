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

# Create Temporary folder nearby

# Link all files into the folder, using sequential naming
# run ffmpeg command to compress a video
archive = (root, metadata, callback)->
  # Create a temporary file to work in.
  temp.mkdir {dir: root}, (err, working)->
    return callback err if err

    # Gather intel
    max_width = 0
    max_height = 0
    for data in metadata
      # Collect the maximum size of our video
      if data.rotate
        max_width = Math.max max_width, data.height
        max_height = Math.max max_height, data.width
      else
        max_width = Math.max max_width, data.width
        max_height = Math.max max_height, data.height

    console.log max_width, max_height
    console.log metadata
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
