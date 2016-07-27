Hapi = require 'hapi'
Path = require 'path'
bunyan = require 'bunyan'

class Server extends Hapi.Server
  constructor: (options)->
    super()
    @connection
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

    @register plugins, (err) =>

      @views
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

        if options?.rewrites?
          @ext 'onRequest', (request, reply) ->
            if (url = options.rewrites[request.path])?
              request.setUrl url
            # if request.path == '/'
            #   request.setUrl '/templates/pretty.jade/html/files/home.txt'
            reply.continue()

      routes = require './routes'

      routes.forEach (route)=>
        @route route

module.exports =
  Server: Server
