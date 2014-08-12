# Gulp Asset Pipeline Configuration

This [Gulp](https://github.com/gulpjs/gulp/) configuration file defines tasks to compile the assets.
It also defines a development asset web server task.

## Require packages

Gulp to handle the pipeline flow:

    g = require('gulp')
    gutil = require('gulp-util')
    clean = require('gulp-clean')
    watch = require('gulp-watch')
    gzip = require('gulp-gzip')
    notify = require('gulp-notify')
    runSequence = require('run-sequence')
    deployToGithubPages = require('gulp-gh-pages')
    _ = require('lodash')

Webpack to compile the assets:

    webpack = require('webpack')

Express and LiveReload for a development server:

    express = require('express')
    tiny_lr = require('tiny-lr')

A number of low-level utilities:

    util = require('util')
    tty = require('tty')
    path = require('path')
    through2 = require('through2')


A helper for requiring files uncached (useful for config files)

    requireUncached = (path) ->
      delete require.cache[require.resolve(path)]
      require(path)

## Configuration


All file system paths used in the tasks will be from the `paths` object.

    paths = {}

Compilation source root:

    paths.src = 'src'
    paths.srcFiles = "#{paths.src}/**/*"

Distribution destination root:

    paths.dist = 'dist'
    paths.distFiles = "#{paths.dist}/**/*"

Paths handled with Webpack:

    paths.webpackPaths = [
      'src/scripts', 'src/scripts/**/*',
      'src/styles', 'src/styles/**/*',
      'src/images', 'src/images/**/*'
    ]

Files not handled with Webpack that reference Webpack assets:

    paths.replaceAssetRefs = [
      "#{paths.src}/index.html"
    ]

Webpack configuration:

    paths.webpackConfig = './webpack.config.litcoffee'
    loadWebpackConfig = -> requireUncached(paths.webpackConfig)
    webpackConfig = loadWebpackConfig()

## Tasks

Show help when invoked with no arguments

    g.task 'default', ->
      help = """
        Usage: bin/gulp [command]

        Available commands:
          bin/gulp                 # display this help message
          bin/gulp dev             # build and run dev server
          bin/gulp prod            # production build, hash and gzip
          bin/gulp clean           # rm /dist
          bin/gulp build           # development build
          bin/gulp deploy-gh-pages # deploy to Github Pages
      """
      setTimeout (-> console.log help), 200

### `dev`

Run a development server:

    g.task 'dev', ['build'], ->
      servers = createServers(4000, 35729)
      logChange = (evt) -> gutil.log(gutil.colors.cyan(evt.path), 'changed')
      # Run webpack on config changes
      g.watch [paths.webpackConfig], (evt) ->
        logChange evt
        webpackConfig = loadWebpackConfig()
        g.start 'webpack'
      # Run build on app source changes
      g.watch [paths.srcFiles], (evt) ->
        logChange evt
        g.start 'build'
      # Notify browser on distribution changes
      g.watch [paths.distFiles], (evt) ->
        logChange evt
        servers.liveReload.changed body: {files: [evt.path]}


### `prod`

Production build:

    g.task 'prod', (cb) ->
      # Apply production config, pass true to append hashes to file names
      setWebpackConfig loadWebpackConfig().mergeProductionConfig()
      runSequence 'clean', 'build', 'gzip', cb

### `clean`

Clean (remove) the distribution folder:

    g.task 'clean', ->
      g.src(paths.dist, read: false).pipe(clean())

### `build`

Build all assets (development build):

    g.task 'build', (cb) ->
      runSequence 'webpack', 'build-replace-asset-refs', 'copy', cb

### `webpack`

Run webpack to process CoffeeScript, JSX, Sass, inline small resources into the CSS, etc:

    g.task 'webpack', (cb) ->
      gutil.log("[webpack]", 'Compiling...')
      webpack webpackConfig, (err, stats) ->
        if (err) then throw new gutil.PluginError("webpack", err)
        gutil.log("[webpack]", stats.toString(colors: tty.isatty(process.stdout.fd)))
        cb()

### `copy`

Copy non-webpack assets to the distribution:

    g.task 'copy', ->
      g.src([paths.srcFiles].concat(paths.webpackPaths.concat(paths.replaceAssetRefs).map (path) -> "!#{path}")).pipe(g.dest paths.dist)

### `gzip`

GZip assets:

    g.task 'gzip', ->
      g.src(paths.distFiles)
      .on('error', handleErrors)
      .pipe(gzip())
      .pipe(g.dest paths.dist)

### `build-replace-asset-refs`

Add fingerprinting hashes to asset references:

    g.task 'build-replace-asset-refs', ->
      g.src(paths.replaceAssetRefs).pipe(
        replaceWebpackAssetUrlsInFiles(
          requireUncached("./#{paths.dist}/assets/asset-stats.json"),
          webpackConfig.output.publicPath
        )).pipe(g.dest paths.dist)

### `deploy-gh-pages`

Build for gh-pages-branch. Same as production but do not append hashes:

    g.task 'build-gh-pages', (cb) ->
      webpackConfig = _.merge loadWebpackConfig().mergeProductionConfig(),
        output:
         publicPath: "/gulp-webpack-react-bootstrap-sass-template/assets/"
      runSequence 'clean', 'build', cb

Deploy to gh-pages branch:

    g.task 'deploy-gh-pages', ['build-gh-pages'], ->
      g.src(paths.distFiles).pipe(deployToGithubPages(cacheDir: './tmp/.gh-pages-cache'))

## Helpers

Set the "global" `webpackConfig` to argument.

    setWebpackConfig = (conf) ->
      webpackConfig = conf

### `createServers`

Create development assets server and a live reload server

    createServers = (port, lrport) ->
      liveReload = tiny_lr()
      liveReload.listen lrport, ->
        gutil.log 'LiveReload listening on', lrport
      app = express()
      app.use express.static(path.resolve paths.dist)
      app.listen port, ->
        gutil.log 'HTTP server listening on', port
      {liveReload, app}

### `replaceWebpackAssetUrlsInFile`

Replace asset URLs with the ones from Webpack in a file:

    replaceWebpackAssetUrlsInFiles = (stats, publicPath) ->

Return a `through2` object (gulp plugin) that replaces file contents in Vinyl virtual file system:

      through2.obj (vinylFile, enc, cb) ->
        vinylFile.contents = new Buffer(replaceWebpackAssetUrls(String(vinylFile.contents), stats, publicPath))
        @push vinylFile
        cb()

### `replaceWebpackAssetUrls`

Replace asset URLs with the ones from Webpack:

    replaceWebpackAssetUrls = (text, stats, publicPath) ->

For each entry in Webpack stats, such as `{'main': 'assets/main-abcde.js'}`:

      for entryName, targetPath of stats

If source-maps are on, then targetPath is an array such as `['file.js', 'file.js.map'`]`. Get the right file:

        if util.isArray(targetPath)
          targetPath = _.find targetPath, (p) -> path.extname(p).toLowerCase() != '.map'

Replace logical path with the target path:

        ref = "assets/#{entryName}#{path.extname(targetPath)}"
        text = text.replace ref, publicPath + targetPath

All done:

      text

### `handleErrors`

Route non-gulp errors through gulp-notify:

    handleErrors = (args...) ->
      notify.onError(title: 'Error', message: '<%= error.message %>').apply(@, args)
      @emit 'end'
