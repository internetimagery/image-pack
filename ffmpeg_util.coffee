# ffmpeg functionality

ffmpeg = require "ffmpeg-static"
child_process = require 'child_process'

# TODO: Get height/width with ffprobe
# ffprobe -of json -v error -show_entries stream=width,height test\image.jpg

# # Export our functions!
# module.exports = module.exports = {}


# Build an expression to run evaluation on specific frames
module.exports.frame_expression = (frames, command)->
  # If we have some frames, lets make an enormous expression
  if frames.length
    frame_cmd = ("eq(n,#{f})" for f in frames).join "+"
    run_cmd = "if(#{frame_cmd},#{command})".replace /,/g, "\\,"
    return run_cmd
  # If we have no frames. Just throw in the command
  else
    return command.replace /,/g, "\\,"

# create rotate filter expression
module.exports.rotate = (degrees, frames)->
  rotate_cmd = "#{degrees}*PI/180"
  return "rotate='#{frame_expression(frames or [], rotate_cmd)}'"

# Pad out smaller frames with black bars
module.exports.pad = (width, height)->
  return "pad='w=#{width}:h=#{height}'"

# Get dimensions from an image / video
dimensions_extract = /\d{2,}x\d{2,}/
module.exports.dimensions = (src, callback)->
  child_process.execFile ffmpeg.path, ["-i", src], (err)->
    meta = dimensions_extract.exec err.message
    if meta?
      return callback null, meta[0].split "x"
    callback new Error "Bad file: #{img}"

# Run a ffmpeg compression
module.exports.compress = (src, dest, filters, callback)->
  console.log "compressing", src, dest, filters
  callback null
  # child_process.execFile ffmpeg.path,
