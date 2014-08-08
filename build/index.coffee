cheerio = require "cheerio"
glob = require "glob"
fs = require "fs-extra"
PDF = require "pdftotextjs"
sql = require "mssql"
yaml = require "yaml-front-matter"
config = require "../config"

index = {}

output = ->
  fs.outputFileSync "index.json", JSON.stringify index

extract = "EXEC sp_ExtractForCCL @code='', @q='', @key=''"
getTest = (id) ->
  "EXEC sp_GetTestDetailByTestID @testID=#{id}, @site='reflab'"

trim = (str) ->
  str.replace(/\s+/g, " ").trim()

unique = (xs) ->
  xs.filter (x, i, xs) ->
    xs.indexOf(x) is i

addTests = (ids) ->
  con = new sql.Connection config.tims, (err) ->
    throw err if err
  req = new sql.Request con
  len = ids.length
  ids.forEach (id) ->
    req.query getTest(id), (err, xs) ->
      throw err if err
      [x, ...] = xs
      item =
        title: x.PrimaryName
        alias: x.Alias
        lis: x.LISCode
        lfs: x.LFSCode
        cpt: x.CPTCode
        body: x.ClinicalInfo
        type: ["test"]
      index["test/?ID=#{id}"] = item
      unless --len
        con.close()
        output()

getTests = ->
  con = new sql.Connection config.tims, (err) ->
    throw err if err
  req = new sql.Request con
  req.query extract, (err, xs) ->
    throw err if err
    con.close()
    cur = xs.filter (x) ->
      not x.DeletedOn and
      (x.DictIntendedForID is 2 or x.DictIntendedForID is 3)
    addTests unique cur.map (x) -> x.ID

addPdfs = (xs) ->
  xs.forEach (x) ->
    pdf = new PDF "src#{x}"
    pdf.getText (err, text) ->
      throw err if err
      [..., title] = x.split "/"
      item =
        title: title
        body: trim text
        type: ["pdf"]
      index[x.slice 1] = item

addDocs = (xs) ->
  len = xs.length
  xs.forEach (x) ->
    $ = cheerio.load x.__content,
      normalizeWhitespace: true
    pdfs = $("a")
      .filter ->
        href = $(this).attr("href")
        !!href.match /^\/assets.*\.pdf$/
      .map -> $(this).attr("href")
      .toArray()
    item =
      title: x.title
      body: trim $.root().text()
      type: ["page"]
    index[x.id] = item unless x.id is "404"
    addPdfs pdfs
    getTests() unless --len

glob "src/documents/**/*.html", (err, xs) ->
  addDocs xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
