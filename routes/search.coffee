lunr = require "lunr"
searchIndex = require "../search-index"
siteIndex = require "../site-index"

index = lunr.Index.load searchIndex

module.exports = (req, res) ->
  xs = index.search req.body.q
  res.send JSON.stringify xs.map (x, i) ->
    siteIndex[x.ref]
