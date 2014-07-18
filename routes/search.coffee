lunr = require "lunr"
searchIndex = require "../search-index"
siteIndex = require "../site-index"

index = lunr.Index.load searchIndex

module.exports = (req, res) ->
  xs = index.search req.body.q
  unless req.body.filter is "all"
    xs = xs.filter (x) ->
      siteIndex[x.ref].type is req.body.filter
      # x.type is req.body.filter
  res.send JSON.stringify xs.map (x, i) ->
    siteIndex[x.ref]
