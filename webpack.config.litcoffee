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

    cssLoaders = ['style', 'css', 'autoprefixer-loader?browsers=last 2 versions']
    styleModLoaders = [
      { test: /\.scss$/, loaders: cssLoaders.concat([
          "sass?precision=10&outputStyle=expanded&sourceMap=true&includePaths[]=" + path.resolve(__dirname, './bower_components')]) }
      { test: /\.css$/ , loaders: cssLoaders }
    ]

### Static assets

Embed data-URLs into CSS and JS for small images and `.woff` fonts:

    staticModLoaders = [
      { test: /\.gif$/  , loader: "url?limit=10000&mimetype=image/gif" }
      { test: /\.jpg$/  , loader: "url?limit=10000&mimetype=image/jpg" }
      { test: /\.png$/  , loader: "url?limit=10000&mimetype=image/png" }
      { test: /\.woff$/ , loader: "url?limit=10000&mimetype=application/font-woff" }
      { test: /\.woff2$/, loader: "url?limit=10000&mimetype=application/font-woff2" }
      { test: /\.ttf$/  , loader: "file?mimetype=application/vnd.ms-fontobject" }
      { test: /\.eot$/  , loader: "file?mimetype=application/x-font-ttf" }
      { test: /\.svg$/  , loader: "file?mimetype=image/svg+xml" }
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

### Generate a manifest

Generate a manifest mapping logical paths to actual paths:

    generateManifestPlugin = (compiler) ->
      @plugin 'done', (stats) ->
        stats = stats.toJson()

Set target path extension to `.css` for style assets, because we use `ExtractTextPlugin`:

        assetStats = stats.assetsByChunkName
        setCssExt = (p) -> p.replace(/\.js$/, '.css')
        for entryName, entryPath of assetStats when /\.(?:scss|sass|css)$/.test(entries[entryName])
          if _.isArray(entryPath)
            assetStats[entryName] = entryPath.map (p) -> setCssExt(p)
          else
            assetStats[entryName] = setCssExt(entryPath)

Write asset-ref -> asset-hash manifest to outputDir/stats.json

        fs.writeFileSync(path.join(outputDir, "asset-stats.json"), JSON.stringify(stats.assetsByChunkName, null, 2))

### Other options

    _.merge module.exports,

Set compilation target to "web". See [docs](http://webpack.github.io/docs/configuration.html#target).

      target: "web"

Set development options by default:

      cache: true
      debug: true
      # We are watching in Gulp, so tell webpack not to watch
      watch: false
      # watchDelay: 300
      devtool: 'source-map'

Output options:

      output:
        path         : outputDir
        publicPath   : "/assets/"
        filename     : "[name].js"
        chunkFilename: "[name].[id].[chunkhash].js"

Look for required files in bower and node

      resolve:
        modulesDirectories: [
          'src'
          'bower_components'
          'node_modules'
        ]

Define how modules should be loaded based on path extension:

      module:
        loaders: styleModLoaders.concat(scriptModLoaders).concat(staticModLoaders)

Define the plugins:

      plugins: [
        definePlugin
        extractTextPlugin
        generateManifestPlugin
      ]


## Production overrides

Export a method that applies production settings (used in gulpfile):

      mergeProductionConfig: (addHashes = true) ->

Production plugins:

Set `__PRODUCTION__` to true in the `DefinePlugin` instance:

        definePlugin.definitions.__PRODUCTION__ = JSON.stringify(true)

Add content hashes to the output filenames:

        _.merge @,
          output:
            filename: "[name]-[hash].js"

Tell `ExtractTextPlugin` to append hashes:

        extractTextPlugin.filename = '[name]-[hash].css'

Disable development settings:

        _.merge @,
          debug: false
          watch: false
          devtool: null

Turn on production optimizations:

          plugins: @plugins.concat [

Order the modules and chunks by occurrence. This saves space, because often referenced modules and chunks get smaller ids.

            new webpack.optimize.OccurenceOrderPlugin(true)

Minify JavaScript with UglifyJS:

            new webpack.optimize.UglifyJsPlugin()

          ]

[Learn more](https://github.com/webpack/docs/wiki/internal-webpack-plugins#optimize)
about optimization plugins shipped with Webpack.
