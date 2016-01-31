# htmlparser = require 'htmlparser'
# parser = new htmlparser.Parser (err, dom)->
#   parser.parseComplete(rawHtml);

uris = require './uris'

redditImages = (listing)->
  return listing.data.children.map (child)->child.data.url

domImages = (document)->
  images = document.getElementByTagName 'img'
  return images.map (tag)-> tag.attributes['href']
    .filter (s)-> s

filters =
  image: (payload, response)->
    type = response?.headers['content-type']
    if type == 'application/json'
      content = JSON.parse payload
    else if type == 'text/html'
      content = null # htmlparser.parse payload

    if response.host == 'reddit.com'
      reply redditImages content
    else
      reply domImages content


routes = []
routes.push
  method: 'GET'
  path: '/filters/{name}/{uri*}'
  handler: (request, reply) ->
    uri = uris.addScheme request
    filter = filters[request.params.name]
    if not filter
      reply 404
    wreck.get uri, (err, response, payload)->
      if err
        reply err
      reply filter payload, response

# routes.push
#   method: 'GET'
#   path: '/selectors/{name}/{uri*}'
#   #handler: ...

module.exports = routes
