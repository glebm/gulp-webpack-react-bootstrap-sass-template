`/** @jsx React.DOM */`

cx = React.addons.classSet
Masthead = require("./Masthead.coffee")
HeartbeatAnimationGroup = require("./HeartbeatAnimationGroup.coffee")

Tag = React.createClass
  render: ->
    `(
      <span className='label label-primary'>{this.props.children}</span>
    )`

logoUrls = ["gulp-logo.png", "webpack-logo.png", "react-logo.png", "sass-logo.png", "twbs-logo.png"].map (p) -> "/images/#{p}"

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
        <div className='powered-by-panel panel panel-primary'>
          <div className='panel-heading'>
            <h2 className='panel-title'>Powered By</h2>
          </div>
          <div className='panel-body'>
            {logoUrls.map(function(imageURL, i){
              return <HeartbeatAnimationGroup phase={200 * ((i + logoUrls.length / 2) % logoUrls.length)}>
                       <img className='img-responsive' src={imageURL} />
                     </HeartbeatAnimationGroup>;
            })}
          </div>
        </div>
      </div>
    )`

module.exports = StarterApp
