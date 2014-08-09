    `/** @jsx React.DOM */`


Require React using native React minified package for production, since it also excludes debug calls:

    if __PRODUCTION__
      require("script!react/react-with-addons.min.js")
    else
      require("script!react/react-with-addons.js")

Require jQuery:

    require("script!jquery/dist/jquery.js")

Require app:

    StarterApp = require("./components/StarterApp.coffee")

Render app:

    React.renderComponent(`<StarterApp />`, document.getElementById('app'))

