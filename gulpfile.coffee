# Prepare to run!

gulp = require 'gulp'
coffee = require 'gulp-coffee'

gulp.task "default", (e)->
  gulp.src "src/**/*.coffee"
      .pipe coffee()
      .pipe gulp.dest "dist"
