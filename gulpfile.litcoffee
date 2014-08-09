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
      'src/styles', 'src/styles/**/*'
    ]

Files not handled with Webpack that reference Webpack assets:

    paths.replaceAssetRefs = [
      "#{paths.src}/index.html"
    ]

Webpack configuration:

    paths.webpackConfig = './webpack.config.litcoffee'
    webpackConfig = require(paths.webpackConfig)
    webpackCssEntries = ['styles']


## Tasks

Show help when invoked with no arguments

    g.task 'default', ->
      help = """
        Usage: bin/gulp [command]

        Available commands:
          bin/gulp              # display this help message
          bin/gulp dev          # build and run dev server
          bin/gulp prod         # production build, hash and gzip
          bin/gulp clean        # rm /dist
          bin/gulp build        # development build
      """
      setTimeout (-> console.log help), 200

### `dev`

Run a development server:

    g.task 'dev', ['build'], ->
      servers = createServers(4000, 35729)
      logChange = (evt) -> gutil.log(gutil.colors.cyan(evt.path), 'changed')
      # Run webpack on config changes
      g.watch [paths.webpackConfig], (evt) ->
        logChange
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
      # Apply production config, it will append hashes to file names among other things
      webpackConfig.useProductionSettings()
      runSequence 'clean', 'build', 'gzip', cb

### `clean`

Clean (remove) the distribution folder:

    g.task 'clean', ->
      g.src(paths.dist, read: false).pipe(clean())

### `build`

Build all assets (development build):

    g.task 'build', ['webpack', 'copy'], ->

### `webpack`

Run webpack to process CoffeeScript, JSX, Sass, inline small resources into the CSS, etc:

    g.task 'webpack', (cb) ->
      gutil.log("[webpack]", 'Compiling...')
      webpack webpackConfig, (err, stats) ->
        if (err) then throw new gutil.PluginError("webpack", err)
        gutil.log("[webpack]", stats.toString(colors: tty.isatty(process.stdout.fd)))
        # If webpack is configured to add hashes:
        if /\[hash\]/.test(webpackConfig.output.filename)
          # Add the hashes to URLs in files that reference the assets:
          replaceWebpackAssetUrlsInFile(path, stats, webpackConfig) for path in paths.replaceAssetRefs
        cb()

### `copy`

Copy non-webpack assets to the distribution:

    g.task 'copy', ->
      g.src([paths.srcFiles].concat(paths.webpackPaths.map (path) -> "!#{path}")).pipe(g.dest paths.dist)

### `gzip`

GZip assets:

    g.task 'gzip', ->
      g.src(paths.distFiles)
      .on('error', handleErrors)
      .pipe(gzip())
      .pipe(g.dest paths.dist)

## Helpers

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

    replaceWebpackAssetUrlsInFile = (filename, stats, config) ->

Use a `through2` pipe to replace file contents in the vinyl virtual file system:

      g.src(filename)
      .on('error', handleErrors)
      .pipe(
        through2.obj (vinylFile, enc, tCb) ->
          vinylFile.contents = new Buffer(replaceWebpackAssetUrls(String(vinylFile.contents), stats, config))
          @push vinylFile
          tCb()
      )
      .pipe(g.dest(paths.dist))

### `replaceWebpackAssetUrls`

Replace asset URLs with the ones from Webpack:

    replaceWebpackAssetUrls = (text, stats, config) ->

Get webpack stats. `stats.toJson()` is an object, not a string as the name suggests.

      wpStats    = stats.toJson()

Compile a regexp for quickly testing against a list of CSS entries (used below):

      cssEntryRe = new RegExp "^(?:#{webpackCssEntries.join('|')})$"

For each entry in Webpack stats (such as `{'main': 'assets/main-abcde.js'}`):

      for entryName, targetPath of wpStats.assetsByChunkName

First, figure out what the entry's file extension is:

Webpack compiles CSS to JS, so `targetPath` always has `.js` extension. Let's check against a a whitelist:

        entryExt = if cssEntryRe.test(entryName) then '.css' else '.js'

If source-maps are on, then targetPath is an array, such as [ 'file.js', 'file.js.map' ]. Get the right file:

        if util.isArray(targetPath)
          targetPath = _.find targetPath, (p) -> path.extname(p).toLowerCase() == entryExt

Set `targetPath` extension to `.css` because we use ExtractTextPlugin to compile CSS to a `.css` file:

        if entryExt == '.css'
          targetPath = targetPath.replace /\.js$/, '.css'

Replace basic path with the output path:

        text = text.replace "#{entryName}#{entryExt}", targetPath

All done:

      text

### `handleErrors`

Route non-gulp errors through gulp-notify:

    handleErrors = (args...) ->
      notify.onError(title: 'Error', message: '<%= error.message %>').apply(@, args)
      @emit 'end'
