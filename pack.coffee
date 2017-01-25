# Pack images into a video file!
path = require 'path'
fs = require 'fs'

# Get height/width
# ffprobe -of json -v error -show_entries stream=width,height test\image.jpg
# vendor\ffmpeg-3.2.2-win64-static\bin

# Pack images into a video file
module.exports = (src, dest, crf, callback)->
  crf = crf or 18 # Default quality value
  console.log "packing", src, dest

  # Determine what we're using as a source.
  fs.stat src, (err, stats)->
    return callback err if err # Expecting "ENOENT" if not valid path
    if stats.isDirectory()
      # If a directory, collect files within.
      fs.readdir src, (err, files)->
        imgs = (f for f in files when fs.statSync(f).isFile())
        console.log "DIRECTORY"
    else if stats.isFile()
      # If a file is given, use that directly.
      console.log "FILE!"
    else
      return callback new Error "Unrecognised input."
