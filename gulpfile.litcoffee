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
      'src/styles', 'src/styles/**/*',
      'src/images', 'src/images/**/*'
    ]

Files not handled with Webpack that reference Webpack assets:

    paths.replaceAssetRefs = [
      "#{paths.src}/index.html"
    ]

Webpack configuration:

    paths.webpackConfig = './webpack.config.litcoffee'
    loadWebpackConfig = ->
      p = paths.webpackConfig
      delete require.cache[require.resolve(p)] if webpackConfig
      require(p)
    webpackConfig = loadWebpackConfig()

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
      # Apply production config, it will append hashes to file names among other things
      webpackConfig.mergeProductionConfig()
      runSequence 'clean', 'build', 'build-replace-asset-refs', 'gzip', cb

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

### `build-replace-asset-refs`

Add fingerprinting hashes to asset references:

    g.task 'build-replace-asset-refs', (cb) ->
      stats = require("./#{paths.dist}/assets/asset-stats.json")
      for p in paths.replaceAssetRefs
        replaceWebpackAssetUrlsInFile p, stats
      cb()

### `deploy-gh-pages`

Deploy to gh-pages branch:

    g.task 'deploy-gh-pages', ->
      webpackConfig.output.publicPath = "/gulp-webpack-react-bootstrap-sass-template/assets/"
      runSequence 'clean', 'build', ->
        g.src(paths.distFiles).pipe(deployToGithubPages())

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

    replaceWebpackAssetUrlsInFile = (filename, stats) ->

Use a `through2` pipe to replace file contents in the vinyl virtual file system:

      g.src(filename)
      .on('error', handleErrors)
      .pipe(
        through2.obj (vinylFile, enc, tCb) ->
          vinylFile.contents = new Buffer(replaceWebpackAssetUrls(String(vinylFile.contents), stats))
          @push vinylFile
          tCb()
      )
      .pipe(g.dest(paths.dist))

### `replaceWebpackAssetUrls`

Replace asset URLs with the ones from Webpack:

    replaceWebpackAssetUrls = (text, stats) ->

For each entry in Webpack stats (such as `{'main': 'assets/main-abcde.js'}`):

      for entryName, targetPath of stats

If source-maps are on, then targetPath is an array such as `['file.js', 'file.js.map'`]`. Get the right file:

        if util.isArray(targetPath)
          targetPath = _.find targetPath, (p) -> path.extname(p).toLowerCase() != '.map'

Replace logical path with the target path:

        text = text.replace "#{entryName}#{path.extname(targetPath)}", targetPath

All done:

      text

### `handleErrors`

Route non-gulp errors through gulp-notify:

    handleErrors = (args...) ->
      notify.onError(title: 'Error', message: '<%= error.message %>').apply(@, args)
      @emit 'end'
