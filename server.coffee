Hapi = require 'hapi'
Path = require 'path'
bunyan = require 'bunyan'
{extend} = require './helpers'
log = require './log'

routes = require './routes/'

# require('babel-core/register')({
#     presets: ['es2015', 'react']
# })

class Server extends Hapi.Server
  constructor: (options)->
    super()
    @connection
      port: options?.port ? 8001

    plugins = [
      'inert'
      'vision'
      'h2o2'
      ].map (plugin)-> { register: require plugin }

    plugins.push
      register: require 'hapi-bunyan'
      options:
        logger: log.bunyanLogger

    plugins.push
      register: require 'hapi-swagger'
      options:
        info:
          title: 'API'
          version: require('./package').version

    log.debug count: plugins.length, 'registering'
    @register plugins, (err) =>
      log.debug 'registered'

      if err
        console.log err

      @views
        engines:
          html:
            module: require 'handlebars'
            isCached: false
          jade:
            module: require 'jade'
            isCached: false
          # jsx:
          #   module: require 'hapi-react-views'
          #   isCached: false

        defaultExtension: 'html'
          # TODO: must be able to use templates from the enclosing directory
        path: Path.join process.cwd(), 'templates'

      if options?.rewrites?
        if typeof options.rewrites == 'object'
          rewrite = (path)->
            if options.rewrites[path]?
              return options.rewrites[path]
        if typeof options.rewrites == 'function'
          rewrite = options.rewrites

        @ext 'onRequest', (request, reply) ->
          if (path = rewrite request.path )?
            log.debug 'rewrote pathname', {path}
            request.url.pathname = path
            request.setUrl request.url
          reply.continue()

      log.debug count: routes.length, 'adding routes'
      routes.forEach (route)=>
        if route.handler?
          route = extend route,
            config:
              handler: route.config?.handler or route.handler
              tags: ['api']
          delete route.handler
        @route route

module.exports =
  Server: Server
