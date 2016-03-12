test = require 'tape'
{toHtml} = require '../html'

test 'tohtml', (t)->
  t.equal '<a href="http://example.com">foo</a>',
    toHtml
      name: 'foo'
      url: 'http://example.com'

  t.end()
