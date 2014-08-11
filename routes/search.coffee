es = require "elasticsearch"

client = new es.Client
  host: "127.0.0.1:9200"

module.exports = (req, res) ->
  query = {}
  query.q = req.body.q if req.body.q
  query.type = req.body.type if req.body.type
  query.from = (req.body.page - 1) * 10 if req.body.page

  if req.body.q
    client.search query, (err, data) ->
      res.send data.hits
