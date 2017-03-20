csvparse = require 'csv-parse'

toObjectStream = (response)->
  type = response.headers['content-type']
  if not type?
    log.warn headers: response.headers, path: response.path, 'no content-type in response'
    type = 'text/csv'
  switch
    when type.startsWith('text/csv')
      parser = csvparse()#{columns: true})
      parser.on 'error', (err)->
        log.error err, 'parser error'
      if response.payload?
        log.debug payload: response.payload.toString(), 'payload to stream'
        parser.end(response.payload.toString())
        parser
      else
        response.pipe(parser)
    else
      throw new Error "cannot create stream from #{type}"

module.exports =
  toObjectStream: toObjectStream
