var gulp = require("gulp"),
    uglify = require("gulp-uglify"),
    rename = require("gulp-rename"),
    watch = require("gulp-watch");

gulp.task('default', ['build'], function () {
    gulp.start(['watch']);
});

gulp.task('build', function () {
    return gulp.src(['./src/kamome.js'])
        .pipe(uglify())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest('./src'));
});

gulp.task('watch', function () {
    watch(['./src/kamome.js'], function () {
        gulp.start(['build']);
    });
});
