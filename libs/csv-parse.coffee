csvparse = require 'csv-parse'

module.exports = (options)->
  parser = csvparse
    columns: options?.columns ? true
    relax_column_count: options?.relax_column_count ? true
