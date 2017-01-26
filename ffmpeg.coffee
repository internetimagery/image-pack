# ffmpeg functionality

ffmpeg = require "ffmpeg-static"

# Get height/width with ffprobe
# ffprobe -of json -v error -show_entries stream=width,height test\image.jpg



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
rotate = (degrees, frames)->
  rotate_cmd = "#{degrees}*PI/180"
  return "rotate='#{frame_expression(frames or [], rotate_cmd)}'"

# Pad out smaller frames with black bars
pad = (width, height)->
  return "pad='w=#{width}:h=#{height}'"


console.log rotate 45, [4,34,4,1]
