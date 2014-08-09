# Webpack Configuration

[Webpack](https://github.com/webpack/webpack) handles asset compilation (Sass, CoffeeScript, etc).
It also manages loading via JavaScript `require`, Sass `@import`, and CSS `url()`.

First, require the dependencies:

    webpack = require('webpack')
    fs      = require('fs')
    path    = require('path')
    _       = require('lodash')


Define an empty configuration:

    module.exports = {}

Entry bundles, i.e. package source paths. See [docs](http://webpack.github.io/docs/configuration.html#entry).

    entries = module.exports.entry =
      "main"            : "./src/scripts/main.litcoffee"
      "styles"          : "./src/styles/styles.scss"
      "vendor/es5-shim" : "./bower_components/es5-shim/es5-shim.js"
      "vendor/es5-sham" : "./bower_components/es5-shim/es5-sham.js"

Define compiled distribution output directory:

    outputDir = path.join(__dirname, "dist", "assets")

## Loaders

Define how files should be loaded (required) based on the extension.

### Scripts

Process CoffeeScript and JSX.

    jsLoaders = ["jsx"]
    scriptModLoaders = [
      { test: /\.coffee$/   , loaders: jsLoaders.concat(["coffee"]) }
      { test: /\.litcoffee$/, loaders: jsLoaders.concat(["coffee?literate"]) }
      { test: /\.js$/       , loaders: jsLoaders }
    ]

### Styles

Process Sass and use Autoprefixer.

    cssLoaders = ['style', 'css', 'autoprefixer-loader?last 2 versions']
    styleModLoaders = [
      { test: /\.scss$/, loaders: cssLoaders.concat([
          "sass?precision=10&outputStyle=expanded&includePaths[]=" + path.resolve(__dirname, './bower_components')]) }
      { test: /\.css$/ , loaders: cssLoaders }
    ]

### Static assets

Embed data-URLs into CSS and JS for small images and `.woff` fonts:

    staticModLoaders = [
      { test: /\.gif$/ , loader: "url?limit=10000&mimetype=image/gif" }
      { test: /\.jpg$/ , loader: "url?limit=10000&mimetype=image/jpg" }
      { test: /\.png$/ , loader: "url?limit=10000&mimetype=image/png" }
      { test: /\.woff$/, loader: "url?limit=10000&mimetype=application/font-woff" }
      { test: /\.ttf$/ , loader: "file?mimetype=application/vnd.ms-fontobject" }
      { test: /\.eot$/ , loader: "file?mimetype=application/x-font-ttf" }
      { test: /\.svg$/ , loader: "file?mimetype=image/svg+xml" }
    ]

### Output CSS to `.css` files

`ExtractTextPlugin` is an experimental plugin to output CSS in `.css` and not as `.js` files with embedded CSS strings.

Require the plugin:

    ExtractTextPlugin = require("extract-text-webpack-plugin")

Set `styleModLoaders` to use the plugin:

    styleModLoaders = styleModLoaders.map (e) ->
      { test: e.test, loader: ExtractTextPlugin.extract(e.loaders.slice(1).join('!')) }

Create an instance of the extractTextPlugin:

    extractTextPlugin = new ExtractTextPlugin("[name].css", allChunks: true)

### Define macro variables

`DefinePlugin` defines variables to be substituted in the assets (a la macro).

Define `__PRODUCTION__: false` variable (set to true on `useProductionSettings()`):

    definePlugin = new webpack.DefinePlugin(
      __PRODUCTION__: JSON.stringify(false)
    )

### Other options

    _.merge module.exports,

Set compilation target to "web". See [docs](http://webpack.github.io/docs/configuration.html#target).

      target: "web"

Set development options by default:

      debug: true
      # We are watching in Gulp, so tell webpack not to watch
      watch: false
      # watchDelay: 300

Output options:

      output:
        path         : outputDir
        publicPath   : "/assets/"
        filename     : "[name].js"
        chunkFilename: "[name].[id].[chunkhash].js"

Look for required files in bower and node

      resolve:
        modulesDirectories: ['bower_components', 'node_modules']

Define how modules should be loaded based on path extension:

      module:
        loaders: styleModLoaders.concat(scriptModLoaders).concat(staticModLoaders)
        noParse: /\.min\.js$/

Define the plugins:

      plugins: [

`definePlugin` defines variables to be substituted in the assets (a la macro):

        definePlugin

`extractTextPlugin` (defined above) will compile CSS to a .css file, as opposed to inlining it as a string in a .js file.

        extractTextPlugin
      ]


## Production overrides

Export a method that applies production settings (used in gulpfile):

      mergeProductionConfig: ->

Production plugins:

Set `__PRODUCTION__` to true in the `DefinePlugin` instance:

        definePlugin.definitions.__PRODUCTION__ = JSON.stringify(true)

Tell `ExtractTextPlugin` to append hashes (BROKEN, see [plugin issue #9](https://github.com/webpack/extract-text-webpack-plugin/issues/9)):

        extractTextPlugin.filename = '[name]-[hash].css'

Merge in production config (deep merge):

        _.merge @,

Disable development settings:

          debug: false
          watch: false
          devtool: null

Add content hashes to the output filenames:

          output:
            filename: "[name]-[hash].js"

          plugins: @plugins.concat [

Minify JavaScript with UglifyJS:

            new webpack.optimize.UglifyJsPlugin()

Generate asset -> asset-hash manifest:

            generateManifestPlugin = (compiler) ->
              @plugin 'done', (stats) ->
                stats = stats.toJson()

Set target path extension to `.css` for style assets, because we use `ExtractTextPlugin`:

                assetStats = stats.assetsByChunkName
                for entryName, entryPath of assetStats
                  if /\.(?:scss|sass|css)$/.test(entries[entryName])
                    assetStats[entryName] = entryPath.replace(/\.js$/, '.css')

Write asset-ref -> asset-hash manifest to outputDir/stats.json

                fs.writeFileSync(path.join(outputDir, "asset-stats.json"), JSON.stringify(stats.assetsByChunkName, null, 2))

          ]
