cheerio = require "cheerio"
glob = require "glob"
lunr = require "lunr"
fs = require "fs-extra"
PDF = require "pdftotextjs"
sql = require "mssql"
yaml = require "yaml-front-matter"
config = require "../config"

siteIndex = {}

searchIndex = lunr ->
  @field "title", boost: 10
  @field "alias", boost: 10
  @field "lis", boost: 10
  @field "lfs", boost: 10
  @field "cpt", boost: 10
  @field "body"
  @field "type"
  @ref "id"

output = ->
  fs.outputFileSync "search-index.json", JSON.stringify searchIndex.toJSON()
  fs.outputFileSync "site-index.json", JSON.stringify siteIndex
  process.exit 0

# extract = "SELECT * FROM TestInfo"
extract = "EXEC sp_ExtractForCCL @code='', @q='', @key=''"
test = (id) -> "EXEC sp_GetTestDetailByTestID @testID=#{id}, @site='reflab'"

removeEmpty = (xs) ->
  xs.filter (x) ->
    x isnt ""

removeSpaces = (xs) ->
  xs.map (x) ->
    x.replace /\s+/g, " "

breakHyphens = (xs) ->
  xs.map (x) ->
    x.replace "-", " "

unique = (xs) ->
  xs.filter (x, i, xs) ->
    xs.indexOf(x) is i

format = (xs) ->
  unique breakHyphens removeSpaces removeEmpty xs

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
            type: "test"
            id: "test/?ID=#{id}"
          searchIndex.add item
          siteIndex[item.id] = item
          output() unless --pending

addPdfs = (xs) ->
  (xs.map (x) -> "src#{x}").forEach (x) ->
    pdf = new PDF x
    pdf.getText (err, data, cmd) ->
      throw err if err
      [..., title] = x.split "/"
      text = data.replace /\s+/g, " "
      item =
        title: title
        body: text
        type: "pdf"
        id: x.replace "src/", ""
      searchIndex.add item
      siteIndex[item.id] = item

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
    text = html("*")
      .map -> html(this).text().trim()
      .toArray()
    item =
      title: x.title
      body: format(text).join(" ")
      type: "page"
      id: x.id
    searchIndex.add item
    siteIndex[item.id] = item
    addPdfs pdfs
    addTests() unless --pending

glob "src/documents/**/*.html", (err, xs) ->
  addDocs xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
