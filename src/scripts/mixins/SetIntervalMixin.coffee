`/** @jsx React.DOM */`

SetIntervalMixin =
  componentWillMount: ->
    @intervals = []
  setInterval: (args...) ->
    @intervals.push(setInterval.apply(null, args))
  componentWillUnmount: ->
    @intervals.map(clearInterval)

module.exports = SetIntervalMixin
