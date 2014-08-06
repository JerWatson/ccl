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
  process.exit 0

extract = "EXEC sp_ExtractForCCL @code='', @q='', @key=''"
test = (id) -> "EXEC sp_GetTestDetailByTestID @testID=#{id}, @site='reflab'"

removeSpaces = (str) ->
  str.replace /\s+/g, " "

unique = (xs) ->
  xs.filter (x, i, xs) ->
    xs.indexOf(x) is i

addTests = (ids) ->
  conn = new sql.Connection config.tims, (err) ->
    throw err if err
    pending = ids.length
    ids.forEach (id) ->
      req = new sql.Request conn
      req.query test(id), (err, xs) ->
        throw err if err
        [test] = xs
        item =
          title: test.PrimaryName
          alias: test.Alias
          lis: test.LISCode
          lfs: test.LFSCode
          cpt: test.CPTCode
          body: test.ClinicalInfo
          type: ["test"]
        index["test/?ID=#{id}"] = item
        output() unless --pending

getTests = ->
  conn = new sql.Connection config.tims, (err) ->
    throw err if err
    req = new sql.Request conn
    req.query extract, (err, xs) ->
      throw err if err
      conn.close()
      active = xs.filter (x) -> not x.DeletedOn
      addTests unique active.map (x) -> x.ID


addPdfs = (xs) ->
  (xs.map (x) -> "src#{x}").forEach (x) ->
    pdf = new PDF x
    pdf.getText (err, data, cmd) ->
      throw err if err
      [..., title] = x.split "/"
      item =
        title: title
        body: removeSpaces data
        type: ["pdf"]
      index[x.replace "src/", ""] = item

addDocs = (xs) ->
  pending = xs.length
  xs.forEach (x) ->
    html = cheerio.load x.__content,
      normalizeWhitespace: true
    pdfs = html("a")
      .filter ->
        href = html(this).attr("href")
        !!href.match /^\/assets.*\.pdf$/
      .map -> html(this).attr("href")
      .toArray()
    item =
      title: x.title
      body: removeSpaces html.root().text()
      type: ["page"]
    index[x.id] = item
    addPdfs pdfs
    getTests() unless --pending

glob "src/documents/**/*.html", (err, xs) ->
  addDocs xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
