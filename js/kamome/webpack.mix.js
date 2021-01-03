const mix = require('laravel-mix');

mix.setResourceRoot('');
mix.js('src/lib/kamome.js', 'public/')
    // .sass('src/sass/*.scss', 'public/css/')
    .browserSync({
        files: './src/lib/*',
        server: './public/',
        proxy: false
    });
