(function() {
  var coffee, gulp;

  gulp = require('gulp');

  coffee = require('gulp-coffee');

  gulp.task("default", function(e) {
    return gulp.src("src/**/*.coffee").pipe(coffee()).pipe(gulp.dest("dist"));
  });

}).call(this);