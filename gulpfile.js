(function() {
  var coffee, gulp, path;

  path = require('path');

  gulp = require('gulp');

  coffee = require('gulp-coffee');

  gulp.task("default", function(e) {
    return gulp.src("src/**/*.coffee").pipe(coffee()).pipe(gulp.dest("dist"));
  });

}).call(this);
