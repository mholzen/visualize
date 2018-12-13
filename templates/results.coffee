React = require 'react'
request = require 'request'
highland = require 'highland'
{parse} = require '@vonholzen/transform'

class Results extends React.Component
  constructor: (props)->
    super(props)
    this.state =
      results: []

  setStream: (stream) ->
    this.state.stream = stream
      .parse()
      .each (item)->
        this.state.results.push item

  render: ->
    <div>{this.state.results?.length} results</div>

module.exports = Results
