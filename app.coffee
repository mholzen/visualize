React = require 'react'
{render} = require 'react-dom'
SearchForm = require './templates/search.coffee'
Results = require './templates/results.coffee'

results = <Results/>
search = <SearchForm results={results}/>

render search, document.getElementById 'search'
render results, document.getElementById 'results'
