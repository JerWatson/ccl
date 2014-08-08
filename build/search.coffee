es = require "elasticsearch"
{pdfs, tests, pages} = require "../index"

client = new es.Client
  host: "localhost:9200"

putPdfs = ->
  pending = pdfs.length
  pdfs.forEach (pdf) ->
    client.index
      index: "ccl"
      type: "pdf"
      id: pdf.url
      body: pdf
    , (err, res) ->
      throw err if err
      process.exit 0

putTests = ->
  pending = tests.length
  tests.forEach (test) ->
    client.index
      index: "ccl"
      type: "test"
      id: test.url
      body: test
    , (err, res) ->
      throw err if err
      putPdfs() unless --pending

putPages = ->
  pending = pages.length
  pages.forEach (page) ->
    client.index
      index: "ccl"
      type: "page"
      id: page.url
      body: page
    , (err, res) ->
      throw err if err
      putTests() unless --pending

putPages()
