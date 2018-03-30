log = require '../log'
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
  log.debug from
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
      s += '</table>'
      return s
    else
      # display array left to right
      s = '<table><tr>'
      s += from.map((item)->('<td>' + toHtml(item) + '</td>')).join('')
      s += '</tr></table>'
      return s

  else if value instanceof Object
    # serialize the remaining
    s = '<table>'
    for k, v of value
      s += '<tr><td>' + k + '</td>'
      s += '<td>' + toHtml(v,k) + '</td>'
    s += '</table>'
    return s
  else
    if context?.includes 'date'
      from = toDate from, context
      from = moment(from).fromNow()
    else if from?.match? and from?.match /^https?:/
      from = '<a href="' + from + '">' + from[0..80] + '</a>'
    return from?.toString()


toAnchor = (label, href)->
  "<a href='#{href}'>#{label}</a>"

toList = (value, root)->
  if typeof value == 'object'
    '<ul>' +
      for label, path of value
        "<li>" + toAnchor label, root + path

module.exports = {
  toAnchor, toList, toHtml
}
