`/** @jsx React.DOM */`

cx = React.addons.classSet
Masthead = require("./Masthead.coffee")
HeartbeatAnimationGroup = require("./HeartbeatAnimationGroup.coffee")

Tag = React.createClass
  render: ->
    `(
      <span className='label label-primary'>{this.props.children}</span>
    )`

poweredBy = [
  { logoURL: require('images/gulp-logo.png')    }
  { logoURL: require('images/webpack-logo.png') }
  { logoURL: require('images/react-logo.png')   }
  { logoURL: require('images/sass-logo.png')    }
  { logoURL: require('images/twbs-logo.png')    }
]

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
            <a className='btn btn-primary btn-lg' href={this.props.githubUrl}>
              This template on Github <i className='glyphicon glyphicon-arrow-right' />
            </a>
          </p>
          <p>
            <Tag>Sass</Tag> <Tag>Literate CoffeeScript</Tag> <Tag>JSX</Tag> <Tag>Autoprefixer</Tag>
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
        <div className='powered-by-panel panel panel-primary'>
          <div className='panel-heading'>
            <h2 className='panel-title'>Powered By</h2>
          </div>
          <div className='panel-body'>
            {renderPoweredByItems(poweredBy)}
          </div>
        </div>
      </div>
    )`

renderPoweredByItems = (items) ->
  n = items.length
  items.map (item, i) ->
    imageURL = item.logoURL
    `(
      <HeartbeatAnimationGroup phase={200 * ((i + n / 2) % n)}>
      <img className='img-responsive' src={imageURL} key={imageURL} />
      </HeartbeatAnimationGroup>
    )`


module.exports = StarterApp
