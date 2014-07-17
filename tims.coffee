fs = require "fs-extra"
lunr = require "lunr"
sql = require "mssql"
searchIndex = require "./search-index"
siteIndex = require "./site-index"
settings = require "./settings"

index = lunr.Index.load searchIndex

output = ->
  fs.outputFileSync "search-index.json", JSON.stringify index.toJSON()
  fs.outputFileSync "site-index.json", JSON.stringify siteIndex
  process.exit 0

extract = "SELECT * FROM TestInfo"
test = (id) -> "EXEC sp_GetTestDetailByTestID @testID=#{id}, @site='reflab'"

unique = (xs) ->
  xs.filter (x, i, xs) ->
    xs.indexOf(x) is i

conn = new sql.Connection settings.tims, (err) ->
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
        index.add item
        siteIndex[item.id] = item
        output() unless --pending
