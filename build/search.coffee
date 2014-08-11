es = require "elasticsearch"
{pdfs, tests, pages} = require "../index"

client = new es.Client
  host: "localhost:9200"

index = (xs, type, done) ->
  pending = xs.length
  xs.forEach (x) ->
    client.index
      index: "ccl"
      type: type
      id: x.url
      body: x
    , (err, res) ->
      done err if err
      done() unless --pending

index pdfs, "pdf", (err) ->
  throw err if err
  index tests, "test", (err) ->
    throw err if err
    index pages, "page", (err) ->
      throw err if err
      process.exit 0
