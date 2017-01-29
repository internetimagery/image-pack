# ffmpeg functionality

ini = require 'ini'
path = require 'path'
ffmpeg = require "ffmpeg-static"
child_process = require 'child_process'

# TODO: Get height/width with ffprobe
# ffprobe -of json -v error -show_entries stream=width,height test\image.jpg

# Form filter expression
filter_generate = (filters)->
  return [] if not filters
  expression = ("#{name}='#{(key+"="+val for key, val of args).join ":"}'" for name, args of filters).join ","
  return ["-vf", expression]

# Build an expression to run evaluation on specific frames
frame_expression = (frames, command)->
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


# Get dimensions from an image / video
dimensions_extract = /\d{2,}x\d{2,}/
module.exports.dimensions = (src, options={}, callback)->
  child_process.execFile ffmpeg.path, ["-i", src], {cwd: options.cwd or process.cwd()}, (err)->
    meta = dimensions_extract.exec err.message
    if meta?
      return callback null, meta[0].split "x"
    callback new Error "Bad file: #{src}"

# Get metadata from a video / image / thing
module.exports.metadata = (src, options={}, callback)->
  command = [
    "-v", "error" # Quiet on the stdout front!
    "-i", src
    "-f", "ffmetadata"
    "pipe:1" # Funnel output into stdout
  ]
  child_process.execFile ffmpeg.path, command, {cwd: options.cwd or process.cwd()}, (err, stdout)->
    return callback err if err
    return callback null, ini.parse stdout

# Run a ffmpeg compression
module.exports.compress = (src, dest, options = {}, callback)->
  # TODO Build system to accept more types of metadata
  input = ["-y", "-f", "concat", "-safe", 0, "-i", src]
  filters = filter_generate options.vfilter
  opts = ["-crf", options.crf or 18, "-an", "-c:v", "libx265"]
  metadata = ["-metadata", "comment=#{options.metadata.comment}"]
  output = [dest]
  command = input.concat filters.concat opts.concat metadata.concat output
  # console.log "Running command: ffmpeg", command.join " "
  child_process.execFile ffmpeg.path, command, {cwd: options.cwd or process.cwd()}, (err, stdout)->
    callback err

# Pull images back out of compression
module.exports.extract = (src, dest, options={}, callback)->
  # Grab our input
  input = ["-y", "-i", src]
  filters = filter_generate options.vfilter
  # Format our output to provide max quality
  output = switch path.extname(dest).toLowerCase()
    when ".jpg" then ["-qmin", 1, "-qmax", 1, "-qscale", 1, dest]
    when ".jpeg" then ["-qmin", 1, "-qmax", 1, "-qscale", 1, dest]
    else [dest]
  command = input.concat filters.concat output
  # console.log "Running command: ffmpeg", command.join " "
  child_process.execFile ffmpeg.path, command, {cwd: options.cwd or process.cwd()}, (err, stdout)->
    callback err, stdout

  # Crop image using built in javascript. A bit slower.
  # jimp.read src, (err, img)->
  #   return callback err if err
  #   img.crop 0, 0, width, height
  #      .quality 100
  #      .write dest, (err)->
  #        callback err
