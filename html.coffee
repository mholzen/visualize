toDate = require './date'

types = (from)->
  Object.keys(from)

counts = (array)->
  return array.reduce (result, item)->
    result[item] = if item of result then result[item] + 1 else 1
    return result
  , {}

max = (counts)->
  return Object.keys(counts).reduce (result, key) ->
    if counts[key] > result then key else result
  , -Infinity

clusters = (array)->
  result = for key, count of counts(array)
    {key: key, count: count}
  result = result.sort (a,b) -> b.count - a.count
  return result

if not Array.prototype.last
    Array.prototype.last = ->
        return this[this.length - 1]

types = (from)->
  # inferences and describes the type of the argument
  if from instanceof Object
    # an object is described by the collection of its keys
    results.push Object.keys(from)

    # can we infere something from these keys?
    # results.last

reduce = (from)->
  # coalesce an object into a shorter higher level object
  Object.keys(from).reduce (to, key)->
    if key == 'url' and to.name?
      to.anchor =
        href: from.url
        html: to.name
      delete to[name]
    else if key == 'name' and to.url?
      to.anchor =
        html: name
        href: to.url
      delete to[url]
    else
      to[key] = from[key]
  ,{}

semanticQuantity = (from)->
  if from instanceof Array
    return from.reduce (a,b)-> a + b
  else if from instanceof Object
    return (Object.keys from).length
  else
    return 1

iterate = (from)->
  if from instanceof Object
    # iterate through k,v of an object, in the order of highest semantic quantity
    order = []
    order[semanticQuantity(value)] = key for key, value of from
    order.forEach (key)->
      yield { key: from[key] }

moment = require 'moment'

toHtml = (from, context)->
  # the choice of row vs col could be made based on cardinality
  # once made?  does it imply the alternative for the value?
  if from instanceof Array
    # if all items have the same structure, then extract structure into headers
    if (c = clusters(from.map (x) -> Object.keys(x))).length <= 3
      # display array top to bottom
      headers = c[0].key.split ','
      s = '<table><thead>'
      s += headers.map((item)->('<th>' + toHtml(item) + '</th>')).join('')
      s += '</thead>'
      s += from.map (item)->
        r = '<tr>'
        r += headers.map (header)-> '<td>' + toHtml(item[header], header) + '</td>'
          .join ''
        r += '</tr>'
        return r
      .join ''
      return s
    else
      # display array left to right
      s = '<table><tr>'
      s += from.map((item)->('<td>' + toHtml(item) + '</td>')).join('')
      s += '</tr></table>'
      return s

  else if from instanceof Object
    # coalesce / reduce
    smaller = reduce(from)

    # serialize the remaining
    s = '<table>'
    for k, v of from
      s += '<tr><td>' + k + '</td>'
      s += '<td>' + toHtml(v,k) + '</td>'
    s += '</table>'
    return s
  else
    if context?.includes 'date'
      from = toDate from, context
      from = moment(from).fromNow()
    else if from.match /^https?:/
      from = '<a href="' + from + '">' + from[0..80] + '</a>'
    return from.toString()

routes = []

wreck = require 'wreck'
marked = require 'marked'

routes.push
  method: 'GET'
  path: '/html/{uri*}'
  handler: (request, reply) ->
    reply.proxy
      uri: 'http://' + request.info.host + '/' + request.params.uri,
      onResponse: (err, res, request, reply, settings, ttl)->
        wreck.read res, null, (err, payload)->
          if res.headers['content-type'].startsWith 'application/json'
            payload = JSON.parse payload.toString()
            reply toHtml payload
          else
            reply marked( payload.toString() )

{proxy} = require './proxy'
csvparse = require 'csv-parse'
transform = require 'stream-transform'
stream = require 'stream'

routes.push
  method: 'GET'
  path: '/table/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      if err
        reply err
      if response.headers['content-type'].startsWith 'text/csv'
        # TODO: use /csv route instead?
        parser = csvparse
          columns: true

        transformer = transform (record, callback)->
          cells = parser.options.columns.map (col)->"<td>#{record[col]}</td>"
          callback null, '<tr>' + cells.join('') + '</tr>'

        serialize = new stream.Transform
          transform: (chunk, encoding, done)->
            if not this._wroteHeaders
              this.push '<table>' +
                (parser.options.columns.map (col)->"<th>#{col}</th>").join ''
              this._wroteHeaders = true
            this.push chunk?.toString()
            done()
          flush: (done)->
            this.push '</table>'
            done()

        reply response.pipe(parser).pipe(transformer).pipe(serialize)
        .type 'text/html'

module.exports =
  routes: routes
  toHtml: toHtml
