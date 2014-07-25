request = require "request"
qs = require "querystring"

module.exports = (req, res) ->
  url = "http://localhost:3000/search"
  q = "q=#{req.body.q}"
  filter = "filter[type][]=#{req.body.filterBy}"
  query = "#{url}?#{q}&#{filter}"
  # query = "#{url}?#{q}"
  # console.log req.body

  request "#{query}", (err, response, body) ->
    console.log body
    res.send body
