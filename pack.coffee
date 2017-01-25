# Pack images into a video file!
path = require 'path'
fs = require 'fs'
child_process = require 'child_process'
ffmpeg = require 'ffmpeg-static'

# Get height/width
# ffprobe -of json -v error -show_entries stream=width,height test\image.jpg
# vendor\ffmpeg-3.2.2-win64-static\bin

ALLOWED_EXT = [".jpg", ".jpeg"]
# FFMPEG_ROOT = path.join process.cwd(), "vendor", "ffmpeg-3.2.2-win64-static", "bin" # TODO: Make this cross platform
# FFMPEG = path.join FFMPEG_ROOT, "ffmpeg.exe"
# FFPROBE = path.join FFMPEG_ROOT, "ffprobe.exe"

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
            rotate: false # TODO: Rotate images into place as we go
          }
          if i == 0 # We have checked everything
            callback null, data
        else
          return callback new Error "Bad file: #{img}"

# Create Temporary folder nearby

# Link all files into the folder, using sequential naming
# run ffmpeg command to compress a video
archive = (root, images, callback)->
  # Gather intel
  # TODO: add in a check for rotatable images. ie height > width
  max_width = 0
  max_height = 0
  for img in images
    max_width = Math.max max_width, img.width
    max_height = Math.max max_height, img.height

  for img in images
    do (img)->

  index = 0
  padding = images.length.toString().length



# Run ffmpeg command
# ffmpeg -i INPUT.jpg -crf 18 -c:v libx265 -vf pad="w=999:h=999" OUTPUT.mp4


# Pack images into a video file
module.exports = (src, dest, options, callback)->
  options.crf = options.crf or 18 # Default quality value
  console.log "packing", src, dest

  # Determine what we're using as a source.
  fs.stat src, (err, stats)->
    return callback err if err # Expecting "ENOENT" if not valid path
    if stats.isDirectory()
      # If a directory, collect files within.
      fs.readdir src, (err, files)->
        imgs = (f for f in files when fs.statSync(f).isFile() and path.extname(f) in ALLOWED_EXT)
        gather_metadata imgs, (err)->
          console.error err if err
    else if stats.isFile()
      if path.extname(src) in ALLOWED_EXT
        gather_metadata [src], (err)->
          console.error err if err
    else
      return callback new Error "Unrecognised input."
