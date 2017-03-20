csvparse = require 'csv-parse'
_ = require 'lodash'

module.exports = (options)->
  csvparse _.defaults options,
      columns: true
      relax_column_count: true
