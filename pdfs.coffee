glob = require "glob"
lunr = require "lunr"
fs = require "fs-extra"
pdfText = require "pdf-text"
searchIndex = require "./search-index"
siteIndex = require "./site-index"

index = lunr.Index.load searchIndex

done = ->
  fs.outputFileSync "search-index.json", JSON.stringify index.toJSON()
  fs.outputFileSync "site-index.json", JSON.stringify siteIndex

glob "src/assets/**/*.pdf", (err, xs) ->
  throw err if err
  pending = xs.length
  xs.forEach (x) ->
    pdfText x, (err, chunks) ->
      throw err if err
      [..., title] = x.split "/"
      item =
        title: title
        body: chunks.join " "
        type: "download"
        id: x.replace "src/", ""
      index.add item
      siteIndex[item.id] = item
      done() unless --pending
