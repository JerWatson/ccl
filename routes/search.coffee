request = require "request"

module.exports = (req, res) ->
  query = "http://localhost:3000/search"
  
  if req.body.q
    query += "?q=#{req.body.q}"
  if req.body.filterBy
    query += "&filter[type][]=#{req.body.filterBy}"
  if req.body.page
    query += "&offset=#{(req.body.page - 1) * 10}"
  query += "&teaser=body"

  request "#{query}", (err, response, body) ->
    console.log body
    res.send body
