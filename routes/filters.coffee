{proxy, proxyPayload} = require '../proxy'
log = require '../log'
cheerio = require 'cheerio'

require 'datejs'

redditImages = (listing)->
  return listing.data.children.map (child)->child.data.url

domImages = (document)->
  images = document.getElementByTagName 'img'
  return images.map (tag)-> tag.attributes['href']
    .filter (s)-> s

traverse = require 'traverse'
jsonBookmarks = (from)->
  json = JSON.parse from
  results = []
  traverse(json).forEach (item)->
    if item?.type == 'url'
      results.push item
  return results

filters =
  image: (payload, response)->
    type = response?.headers['content-type']
    if type.startsWith 'application/json'
      content = JSON.parse payload
    else if type.startsWith 'text/html'
      content = null # htmlparser.parse payload

    return if response.host == 'reddit.com'
      redditImages content
    else
      domImages content

  bookmarks: (payload, response)->
    return jsonBookmarks payload

  code: (payload, response)->
    type = response?.headers['content-type']
    if type.startsWith 'text/html'
      $ = cheerio.load payload
      $('code').toString()

  recent: (payload, response)->
    type = response?.headers['content-type']
    if type.startsWith 'application/json'
      content = JSON.parse payload
    since = Date.today().addDays(-120).getTime()
    c = content.filter (item)->
      # Date.compare(Date.parse(item['Date']),since) == 1
      (new Date(item['Date'])).getTime() > since
    c

  url: (payload, response)->
    type = response?.headers['content-type']
    if type.startsWith 'text/html'
      $ = cheerio.load payload
      result = $('a').map ()->$(this).attr('href')
      return JSON.stringify(result.get())


wreck = require 'wreck'

routes = []
routes.push
  method: 'GET'
  path: '/filters/{name}/{uri*}'
  handler: (request, reply) ->
    filter = filters[request.params.name]
    if not filter
      reply 404, "cannot find filter #{request.params.name}"
    proxyPayload request, reply, (err, response, payload)->
      reply filter payload, response

# grep = array.filter regexp
# or
# JSONPath json: obj, path: '$.*', callback: (item)-> request.params.pattern.match item

match = (matching)->
  if typeof matching == 'function'
    return matching
  if typeof matching == 'string'
    log.debug 'constructing regexp test function using string ' + matching
    matching = new RegExp matching, 'i'
    f = (item)->
      log.debug 'testing ' + item + ' for ' + matching
      if item instanceof Array
        index = item.findIndex (item)->
          # item.includes matching # could recurse
          matching.test item # could recurse
        return index >= 0
      if typeof item == 'object'
        log.debug item + ' is an object'
        for key in item
          if f item[key]
          # if matching.test item[key]  # could recurse
            return true
      false

# returns just the key/value that matches
filterObject = (object, matching)->
  test = match matching
  Object.keys(object).reduce (result, key)->
    if test object[key]
      result[key] = object[key]
    return result
  , {}

# retuns the entire object
testObject = (object, matching)->
  test = match matching
  for k, v of json
    if test v
      return object

filterJson = (json, matching)->
  test = match matching
  if json instanceof Array
    return json.filter test
  if typeof json == 'object'
    return filterObject json, matching
  if test json
    return json

csvparse = require 'csv-parse/lib/sync'   # TODO: optimize


filter = (request, payload, response)->
  pattern = request.params.pattern
  type = response.headers['content-type']
  if type.startsWith 'application/json'
    if not request.json?    # json(request)
      request.json = JSON.parse payload

    # tree search pattern: xpath, jsonpath, css
    # https://github.com/s3u/JSONPath
    # path = request.params.path or '$.*'
    # JSONPath = require 'jsonpath-plus'
    # result = JSONPath
    #   json: request.json
    #   path: request.params.path
    #   callback: (item)-> pattern.match item
    return filterJson request.json, pattern
  if type.startsWith 'text/csv'
    if not request.csv?
      request.csv = csvparse payload
    return filterJson request.csv, pattern

  return "don't know how filter object of type #{type}"

routes.push
  method: 'GET'
  path: '/filters2/{pattern}/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      # TODO: filter() returns an object which sets the response type to json
      # should return the content type of the response
      reply filter request, payload, response


# routes.push
#   method: 'GET'
#   path: '/selectors/{name}/{uri*}'
#   #handler: ...

module.exports = routes
