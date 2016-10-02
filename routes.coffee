routes = []

routes.push
  method: 'GET',
  path: '/'
  config:
    handler: (request, reply)->
      reply.redirect '/html/text/files/index'

Path = require 'path'

routes.push
  method: 'GET',
  path: '/files/{param*}',
  config:
    handler:
      directory:
        path: Path.join process.cwd(), 'files'
        listing: true

routes.push (require './routes/graph')...

routes.push (require './routes/slice')...

routes.push (require './routes/join')...

routes.push (require './routes/tail')...

routes.push
  method: 'GET'
  path: '/chart/{uri*}'
  config:
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
