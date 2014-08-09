path = require("path")
webpack = require("webpack")
_ = require('lodash')

plugins = [ new webpack.DefinePlugin(__PRODUCTION__: JSON.stringify(false)) ]

cssLoaders = ['style', 'css', 'autoprefixer-loader?last 2 versions']
styleLoaders = [
  { test: /\.scss$/, loaders: cssLoaders.concat(["sass?precision=10&outputStyle=expanded&includePaths[]=" + path.resolve(__dirname, './bower_components')]) }
  { test: /\.css$/, loaders: cssLoaders }
]

# By default, webpack bundles CSS as a String wrapped in JavaScript...
# Enable experimental (!) plugin to bundle CSS as CSS:
ExtractTextPlugin = require("extract-text-webpack-plugin")
styleLoaders = styleLoaders.map (e) ->
  test: e.test
  loader: ExtractTextPlugin.extract(e.loaders.slice(1).join('!'))
plugins.push(new ExtractTextPlugin("[name]", allChunks: true))

module.exports =
  # This is the main file that should include all other JS files
  entry:
    main             : "./src/scripts/main.litcoffee"
    "styles.css"     : "./src/styles/styles.scss"
    "vendor/es5-shim": "./bower_components/es5-shim/es5-shim.js"
    "vendor/es5-sham": "./bower_components/es5-shim/es5-sham.js"
  target: "web"
  debug: true
  # We are watching in the gulp.watch, so tell webpack not to watch
  watch: false
  # watchDelay: 300
  output:
    path: path.join(__dirname, "dist", "assets")
    publicPath: "/assets/"
    # If you want to generate a filename with a hash of the content (for cache-busting)
    # filename: "main-[hash].js",
    filename: "[name].js"
    chunkFilename: "[name].[id].[chunkhash].js"
  resolve:
    # Tell webpack to look for required files in bower and node
    modulesDirectories: ['bower_components', 'node_modules']
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
  plugins: plugins
  # A custom property, when called sets settings for compiling assets in production mode
  useProductionSettings: ->
    config = @
    config.plugins = config.plugins.concat [
      new webpack.DefinePlugin(__PRODUCTION__ : JSON.stringify(true)),
      new webpack.optimize.UglifyJsPlugin()
    ]
    config.watch = false
    config.devtool = null
    config.output.filename = "[name]-[hash].js"
    @
