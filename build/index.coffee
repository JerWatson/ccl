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

addTests = ->
  conn = new sql.Connection config.tims, (err) ->
    throw err if err
    req = new sql.Request conn
    req.query extract, (err, xs) ->
      throw err if err
      act = xs.filter (x) -> not x.DeletedOn
      ids = unique act.map (x) -> x.ID
      pending = ids.length
      ids.forEach (id) ->
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
            id: "test/?ID=#{id}"
          index[item.id] = item
          output() unless --pending

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
        id: x.replace "src/", ""
      index[item.id] = item

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
      id: x.id
    index[item.id] = item
    addPdfs pdfs
    addTests() unless --pending

glob "src/documents/**/*.html", (err, xs) ->
  addDocs xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
