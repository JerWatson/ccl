es = require "elasticsearch"
index = require "../index"

client = new es.Client
  host: "localhost:9200"
  log: "trace"

for pdf in index.pdfs
  client.index
    index: "ccl"
    type: "pdf"
    id: pdf.url
    body: pdf
  , (err, res) ->
    throw err if err

for test in index.tests
  client.index
    index: "ccl"
    type: "test"
    id: test.url
    body: test
  , (err, res) ->
    throw err if err

for page in index.pages
  client.index
    index: "ccl"
    type: "page"
    id: page.url
    body: page
  , (err, res) ->
    throw err if err
