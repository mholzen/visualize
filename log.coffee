bunyan = require 'bunyan'
log = require 'log'

bunyanLogger = bunyan.createLogger
  name: 'visualize', level: 'debug'

log.write = ->
  bunyanLogger.debug arguments...

logLevel = (level)->
  ->
    log.write = -> bunyanLogger[level] arguments...
    log arguments...

log.debug = logLevel 'debug'
log.info = logLevel 'info'
log.warn = logLevel 'warn'
log.error = logLevel 'error'
log.bunyanLogger = bunyanLogger

module.exports = log
