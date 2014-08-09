`/** @jsx React.DOM */`

cx = React.addons.classSet
Masthead = require("./Masthead.coffee")

ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

FadeImage = React.createClass
  render: ->
    classes = ['img-responsive'].concat(this.props.className || []).join(' ')
    `(
      <ReactCSSTransitionGroup transitionName="fade">
        <img className={classes} src={this.props.url} key={this.props.url} />
      </ReactCSSTransitionGroup>
    )`
imageURL = "/images/BladeRunner.gif"

Tag = React.createClass
  render: ->
    `(
      <span className='label label-primary'>{this.props.children}</span>
    )`

StarterApp = React.createClass
  render: ->
    `(
      <div className='main text-center'>
        <Masthead title="Gulp, Webpack, React, bootstrap-sass.">
          <p>
            This template brings together all the pieces you need to start building your first React app. <br />
            Gulp is used for orchestrating the build process, and Webpack is used to compile and package assets.
          </p>
          <p>
            <Tag>Sass</Tag> <Tag>CoffeeScript</Tag> <Tag>JSX</Tag> <Tag>Autoprefixer</Tag>
          </p>
          <table className='table test-features'>
            <tbody>
              <tr>
                <td className='text-right'> Glyphicon                                   </td>
                <td> <code>glyphicon-user</code>                                        </td>
                <td className='text-left'> <i className="glyphicon glyphicon-user"></i> </td>
              </tr>
              <tr>
                <td className='text-right'> React expression                            </td>
                <td> <code>{'{15 * 20}'}</code>                                           </td>
                <td className='text-left'> {15 * 20}                                      </td>
              </tr>
            </tbody>
          </table>
        </Masthead>
        <FadeImage className='center-block' url={imageURL} />
      </div>
    )`

module.exports = StarterApp
