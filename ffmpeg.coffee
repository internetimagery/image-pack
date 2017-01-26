# ffmpeg functionality

ffmpeg = require "ffmpeg-static"

# rotate: -vf rotate="if(eq(n\,FRAME)\,90*PI/180)"

# Build an expression to run evaluation on specific frames
build_expression = (frames, command)->
  # If we have some frames, lets make an enormous expression
  if frames.length
    frame_cmd = ("eq(n,#{f})" for f in frames).join "+"
    run_cmd = "if(#{frame_cmd},#{command})".replace /,/g, "\\,"
    return run_cmd
  # If we have no frames. Just throw in the command
  else
    return command.replace /,/g, "\\,"

build_expression [2,3,6,10,9], "90*PI/180"
