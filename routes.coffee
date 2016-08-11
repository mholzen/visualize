routes = []

routes.push
  method: 'GET',
  path: '/'
  handler: (request, reply)->
    reply.redirect '/html/text/files/index'

Path = require 'path'

routes.push
  method: 'GET',
  path: '/files/{param*}',
  handler:
    directory:
      path: Path.join __dirname, 'files'
      listing: true

routes.push (require './routes/graph')...

routes.push
  method: 'GET'
  path: '/csv2json/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      csvparse payload.toString(), {columns: true}, (err, output)->
        reply output


routes.push
  method: 'GET'
  path: '/chart/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      reply.view 'chart',
        uri: request.params.uri
        content: payload.toString()

routes.push require './slideshow'

routes.push (require './templates') ...

routes.push require './filters'

routes.push require './maps'

routes.push require './transform'

routes.push require './sort'

routes.push (require './html').routes

module.exports = routes
