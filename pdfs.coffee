glob = require "glob"
lunr = require "lunr"
fs = require "fs-extra"
PDF = require "pdftotextjs"
searchIndex = require "./search-index"
siteIndex = require "./site-index"

index = lunr.Index.load searchIndex

output = ->
  fs.outputFileSync "search-index.json", JSON.stringify index.toJSON()
  fs.outputFileSync "site-index.json", JSON.stringify siteIndex

glob "src/assets/**/*.pdf", (err, xs) ->
  throw err if err
  pending = xs.length
  xs.forEach (x) ->
    pdf = new PDF x
    pdf.getText (err, data, cmd) ->
      throw err if err
      [..., title] = x.split "/"
      text = data.replace /\s+/g, " "
      item =
        title: title
        body: text
        type: "document"
        id: x.replace "src/", ""
      index.add item
      siteIndex[item.id] = item
      output() unless --pending
