context = require "search-context"
es = require "elasticsearch"

client = new es.Client
  host: "http://localhost:9200"

module.exports = (req, res) ->
  query = {}
  query.q = req.body.q if req.body.q
  query.type = req.body.type if req.body.type
  query.from = (req.body.page - 1) * 10 if req.body.page

  if req.body.q
    client.search query, (err, data) ->
      data.hits.hits.forEach (hit) ->
        hit._source.text = context hit._source.text, req.body.q.split(" "), 250, (str) -> "<strong>#{str}</strong>"
      res.send data.hits
