`/** @jsx React.DOM */`

Masthead = React.createClass
  render: () ->
    `(
      <div className='bs-masthead'>
        <div className="container">
          <h1>{this.props.title}</h1>
          <div className="lead">{this.props.children}</div>
        </div>
      </div>
    )`

module.exports = Masthead
