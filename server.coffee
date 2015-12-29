Hapi = require 'hapi'

server = new Hapi.Server()

server.connection
  port: 8001

Path = require 'path'

server.views
  engines:
    html:
      module: require 'handlebars'
      isCached: false
    jade:
      module: require 'jade'
      isCached: false
  defaultExtension: 'html'
  # TODO: must be able to use templates from the enclosing directory
  path: Path.join __dirname, 'templates'

routes = require './routes'

routes.forEach (route)->
  server.route route

module.exports = server
