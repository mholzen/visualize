Hapi = require 'hapi'
Path = require 'path'
bunyan = require 'bunyan'
{extend} = require './helpers'
log = require './log'

routes = require './routes/'

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
        logger: log

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
        defaultExtension: 'html'
        # TODO: must be able to use templates from the enclosing directory
        path: Path.join process.cwd(), 'templates'

      if options?.rewrites?
        rewrite = if typeof options.rewrites == 'object'
            (path)-> options.rewrites[path]
          else
            options.rewrites

        @ext 'onRequest', (request, reply) ->
          if (url = rewrite request.path )?
            log.debug {url}, 'rewrote path to url'
            request.setUrl url
          reply.continue()

      log.debug count: routes.length, 'adding routes'
      routes.forEach (route)=>
        route = extend route,
          config:
            handler: route.config?.handler or route.handler
            tags: ['api']
        delete route.handler
        @route route

module.exports =
  Server: Server
