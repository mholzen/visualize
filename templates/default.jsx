// Default layout template
var React = require('react');
var SearchForm = require('./search');

class Default extends React.Component {

  render() {
    return(
      <html>
      <head>

        <meta charSet="utf-8"></meta>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"></meta>
        <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css" rel="stylesheet"></link>

      </head>
      <body>
        <SearchForm/>
      </body>
      </html>
    );
  }
}

module.exports = Default;
