{toHtml} = require '../libs/html'

routes = []

wreck = require 'wreck'
marked = require 'marked'
{proxy, proxyPayload} = require '../proxy'

routes.push
  method: 'GET'
  path: '/html/{uri*}'
  handler: (request, reply) ->
    proxyPayload request, reply, (err, response, payload)->
      type = response.headers['content-type'] ? ''
      if type.startsWith 'application/json'
        payload = JSON.parse payload.toString()
        reply toHtml payload
      else if type.startsWith('text/plain') or type.startsWith('application/octet-stream')
        reply marked( payload.toString() )
      else
        reply(payload).headers = response.headers

csvparse = require '../libs/csv-parse'
transform = require 'stream-transform'
stream = require 'stream'

routes.push
  method: 'GET'
  path: '/table/{uri*}'
  handler: (request, reply) ->
    proxy request, reply, (err, response)->
      if err
        reply err
      if response.headers['content-type'].startsWith 'text/csv'
        # TODO: use /csv route instead?
        parser = csvparse()

        transformer = transform (record, callback)->
          cells = parser.options.columns.map (col)->"<td>#{record[col]}</td>"
          callback null, '<tr>' + cells.join('') + '</tr>'

        serialize = new stream.Transform
          transform: (chunk, encoding, done)->
            if not this._wroteHeaders
              this.push '<table>' +
                (parser.options.columns.map (col)->"<th>#{col}</th>").join ''
              this._wroteHeaders = true
            this.push chunk?.toString()
            done()
          flush: (done)->
            this.push '</table>'
            done()

        reply response.pipe(parser).pipe(transformer).pipe(serialize)
        .type 'text/html'

module.exports = routes
