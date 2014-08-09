# Webpack Configuration

[Webpack](https://github.com/webpack/webpack) handles asset compilation (Sass, CoffeeScript, etc),
and processes JS `require`, Sass `@import`, and CSS `url()`.

First, require the dependencies:

    path    = require('path')
    webpack = require('webpack')
    _       = require('lodash')

## CSS configuration

List of loader names for CSS files:

    cssLoaders = ['style', 'css', 'autoprefixer-loader?last 2 versions']

Style module loaders (used later):

    styleLoaders = [
      { test: /\.scss$/, loaders: cssLoaders.concat(["sass?precision=10&outputStyle=expanded&includePaths[]=" + path.resolve(__dirname, './bower_components')]) }
      { test: /\.css$/, loaders: cssLoaders }
    ]

`ExtractTextPlugin` is an experimental plugin to output CSS in `.css` and not `.js` files. Create plugin instance (used later):

    ExtractTextPlugin = require("extract-text-webpack-plugin")
    extractTextPlugin = new ExtractTextPlugin("[name].css", allChunks: true)

Override style loaders to use `ExtractTextPlugin`:

    styleLoaders = styleLoaders.map (e) ->
      test: e.test
      loader: ExtractTextPlugin.extract(e.loaders.slice(1).join('!'))

## Configuration

    module.exports =

List of bundle entry points, i.e. packages to compile in the distribution. See [docs](http://webpack.github.io/docs/configuration.html#entry).

      entry:
        main             : "./src/scripts/main.litcoffee"
        "styles"         : "./src/styles/styles.scss"
        "vendor/es5-shim": "./bower_components/es5-shim/es5-shim.js"
        "vendor/es5-sham": "./bower_components/es5-shim/es5-sham.js"

Set compilation target to "web". See [docs](http://webpack.github.io/docs/configuration.html#target).

      target: "web"

Set development options by default:

      debug: true
      # We are watching in Gulp, so tell webpack not to watch
      watch: false
      # watchDelay: 300

Output options:

      output:
        path         : path.join(__dirname, "dist", "assets")
        publicPath   : "/assets/"
        filename     : "[name].js"
        chunkFilename: "[name].[id].[chunkhash].js"

Look for required files in bower and node

      resolve:
        modulesDirectories: ['bower_components', 'node_modules']

Define how modules should be loaded based on path extension:

      module:
        loaders: styleLoaders.concat [
          { test: /\.gif$/, loader: "url?limit=10000&minetype=image/gif" }
          { test: /\.jpg$/, loader: "url?limit=10000&minetype=image/jpg" }
          { test: /\.png$/, loader: "url?limit=10000&minetype=image/png" }
          { test: /\.js$/, loader: "jsx" }
          { test: /\.coffee$/, loader: "jsx!coffee" }
          { test: /\.litcoffee$/, loader: "jsx!coffee?literate"}
          # url-loader embeds DataUrls.
          { test: /\.woff$/, loader: "url?limit=10000&minetype=application/font-woff" }
          # file-loader emits files.
          { test: /\.ttf$/, loader: "file?mimetype=application/vnd.ms-fontobject" }
          { test: /\.eot$/, loader: "file?mimetype=application/x-font-ttf" }
          { test: /\.svg$/, loader: "file?mimetype=image/svg+xml" }
        ]
        noParse: /\.min\.js$/

Define the plugins:

      plugins: [

`DefinePlugin` defines a variable that will be substituted in the assets (a la macro):

        new webpack.DefinePlugin(__PRODUCTION__: JSON.stringify(false))

`extractTextPlugin` (defined above) will compile CSS to a .css file, as opposed to inlining it as a string in a .js file.

        extractTextPlugin
      ]


## Production

Export a method that applies production settings (used in gulpfile):

      useProductionSettings: ->

Production plugins:

        plugins = @plugins.concat [

Minify JavaScript with UglifyJS:

          new webpack.optimize.UglifyJsPlugin()
        ]

Set `__PRODUCTION__` to true in the `DefinePlugin` instance:

        for plugin in plugins when plugin.definitions?.__PRODUCTION__
          plugin.definitions.__PRODUCTION__ = JSON.stringify(true)

Tell `ExtractTextPlugin` to append hashes (BROKEN, see [plugin issue #9](https://github.com/webpack/extract-text-webpack-plugin/issues/9)):

        for plugin in plugins when plugin.filename == '[name].css'
          plugin.filename = '[name]-[hash].css'

Merge in production config (deep merge):

        _.merge @,

Disable development settings:

          debug: false
          watch: false
          devtool: null

Add content hashes to the output filenames:

          output:
            filename: "[name]-[hash].js"

Production-only plugins:

          plugins: plugins
