`/** @jsx React.DOM */`

Masthead = require("./Masthead.coffee")

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

FadeImage = React.createClass
  componentDidMount: ->
    self = this;

  render: ->
    `(
      <ReactCSSTransitionGroup transitionName="fade">
        <img src={this.props.url} key={this.props.url} />
      </ReactCSSTransitionGroup>
    )`
imageURL = "/images/BladeRunner.gif"

StarterApp = React.createClass
  render: () ->
    `(
      <div className='main'>
        <Masthead title="Gulp + Webpack (CoffeeScript, Sass, JSX) + React + Bootstrap for Sass">
          This template brings together all the pieces you need to start building your first React app.
          Gulp is used for orchastrating the build process, and Webpack is used to combine the Javascripts together.
          <p className='lead'>
            Search icon <i className="glyphicon glyphicon-search"> </i>
            <br />
            {'{1 + 2}'} = {1 + 2}
          </p>
        </Masthead>
        <div className='text-center'>
          <FadeImage url={imageURL} />
        </div>
      </div>
    )`

module.exports = StarterApp
