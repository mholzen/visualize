csvparse = require 'csv-parse'
split = require 'split2'
CSON = require 'cson-parser'
highland = require 'highland'


toObjectStream = (response)->
  type = response.headers['content-type']
  if not type?
    log.warn headers: response.headers, path: response.path, 'no content-type in response'
    type = 'text/csv'
  switch
    when type.startsWith 'application/json'
      # WARNING: assumes it is JSON lines.  what if single JSON object?
      # response.pipe(split(CSON.parse))
      response.pipe CSON.parse
    when type.startsWith('text/plain') or type.startsWith('application/octet-stream')
      highland(response).split()
    when type.startsWith('text/csv')
      parser = csvparse()#{columns: true})
      parser.on 'error', (err)->
        log.error err, 'parser error'
      if response.payload?
        log.debug payload: response.payload.toString(), 'payload to stream'
        parser.end(response.payload.toString())
        parser
      else
        response.pipe parser
    else
      throw new Error "cannot create stream from #{type}"

toHighland = (respone)->
  highland(toObjectStream(respone))

module.exports = {
  toObjectStream
  toHighland
}
