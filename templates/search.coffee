React = require 'react'
request = require 'request'
stream = require 'highland'
{parse} = require '@vonholzen/transform'

class SearchForm extends React.Component
  constructor: (props)->
    super(props)
    console.log props
    this.state = {value: ''}
    this.handleChange = this.handleChange.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)

  handleChange: (event)->
    this.setState
      value: event.target.value

  handleSubmit: (event)=>
    stream(request.get(location.origin + '/search?type=url&name='+this.state.value))
    .split()
    .filter (line) -> line.length > 0
    .map parse
    .each (item)=>
      current = this.props.results.state;
      this.props.results.setState {results: current.push(item) }

    event.preventDefault()

  render: ->
    <form onSubmit={this.handleSubmit}>
      <label>
        Search:
        <input type="text" value={this.state.value} onChange={this.handleChange} />
      </label>
      <input type="submit" value="Submit" />
    </form>

module.exports = SearchForm
