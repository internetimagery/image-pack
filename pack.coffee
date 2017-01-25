# Pack images into a video file!

# Pack images into a video file
module.exports = (src, dest, crf)->
  crf = crf or 18 # Default quality value
  console.log "packing", src, dest
