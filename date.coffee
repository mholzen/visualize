# chrome bookmarks
bookmarkToDate = (from)->
  new Date(1601, 0, 0, 0, 0, parseInt(from) / 1000000 )

toDate = (from, context)->
  if context?.includes 'date_added'
    bookmarkToDate from
  else if from.match /\d+/
    new Date(parseInt(from))
  else
    Date.parse(from)

module.exports = toDate
