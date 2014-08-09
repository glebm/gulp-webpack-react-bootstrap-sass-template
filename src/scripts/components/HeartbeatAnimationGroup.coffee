`/** @jsx React.DOM */`

HeartbeatAnimationGroup = React.createClass
  mixins: [require('scripts/mixins/SetIntervalMixin.coffee')]

  getDefaultProps: ->
    phase: 0
    center: 0.7
    amplitude: 0.2
    steps: 2
    transition: 'all 650ms ease-in-out'
    tickInterval: 650

  getInitialState: ->
    ticks: 0

  componentDidMount: ->
    setTimeout (=> @setInterval (=> @tick()), 650), @props.phase

  tick: ->
    @setState(ticks: @state.ticks + 1)

  scale: ->
    @props.center + @props.amplitude / 2.0 - @props.amplitude / (1 + @state.ticks % @props.steps)

  render: ->
    `(
    <div className={this.props.className} style={{transition: this.props.transition, transform: 'scale(' + this.scale() + ')'}}>
      {this.props.children}
    </div>
    )`

module.exports = HeartbeatAnimationGroup
