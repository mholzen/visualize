Hapi = require 'hapi'
Path = require 'path'
bunyan = require 'bunyan'

server = new Hapi.Server()

server.connection
  port: 8001


plugins = [
  'inert'
  'vision'
  'h2o2'
  ].map (plugin)-> { register: require plugin }

log = bunyan.createLogger { name: 'test', level: 'debug' }

plugins.push
  register: require 'hapi-bunyan'
  options: log

server.register plugins, (err) =>

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
