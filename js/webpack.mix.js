const mix = require('laravel-mix');

mix.setResourceRoot('');
mix.js('src/kamome.js', 'public/')
    // .sass('src/sass/*.scss', 'public/css/')
    .browserSync({
        files:  './src/*',
        server: './public/',
        proxy:  false
    });
