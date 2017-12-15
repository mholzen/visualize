var path = require('path');
var suite = require('webpack-dependency-suite');

module.exports = {
  entry: './app.coffee',
  output: {
    filename: 'files/bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: [
          'babel-loader',
          'coffee-loader'
        ]
      },
      {
        test: /\.jsx$/,
        use: [ 'babel-loader' ]
      }
    ]
  },
  resolve: {
    extensions: [ '.coffee', '.js' ]
  },
  node: {
    console: true,
    fs: 'empty',
    net: 'empty',
    tls: 'empty'
  }
}
