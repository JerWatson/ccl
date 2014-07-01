cheerio = require "cheerio"
ect = require "ect"
fs = require "fs-extra"
glob = require "glob"
lunr = require "lunr"
sm = require "sitemap"
yaml = require "yaml-front-matter"

results = {}

index = lunr ->
  @field "title", boost: 10
  @field "body"

renderer = ect
  root: "#{__dirname}/src/layouts"
  ext: ".ect"
  open: "{{"
  close: "}}"

site = sm.createSitemap
  hostname: "http://clevelandcliniclabs.com"

notEmpty = (xs) ->
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

formatText = (xs) ->
  unique breakHyphens removeSpaces notEmpty xs

documents = (done) ->
  res = []
  glob "src/documents/**/*.html", (err, list) ->
    done err if err
    pending = list.length
    done null, res unless pending
    list.forEach (item) ->
      fs.readFile item, "utf8", (err, data) ->
        file = yaml.loadFront data
        html = cheerio.load file.__content,
          normalizeWhitespace: true
        text = html("*")
          .map -> html(this).text().trim()
          .toArray()
        doc =
          title: file.title
          body: formatText(text).join " "
          id: file.id
        index.add doc
        results[doc.id] = doc
        res.push file
        done null, res unless --pending

parent = (page, list) ->
  list.filter (item) ->
    item.id is page.parent

children = (page, list) ->
  list.filter (item) ->
    item.parent is page.id

sidenav = (page, list) ->
  if page.isParent
    list.filter (item) ->
      item.id is page.id or item.parent is page.id
  else if page.parent
    list.filter (item) ->
      item.id is page.parent or item.parent is page.parent
  else []

sitemap = ->
  glob "out/**/*.html", (err, list) ->
    throw err if err
    list.forEach (item) ->
      item = item.replace "out", ""
      site.add url: item unless item is "/404/index.html"
    fs.outputFile "out/sitemap.xml", site, (err) ->
      throw err if err

documents (err, docs) ->
  throw err if err
  docs.forEach (doc) ->
    dest = if doc.isHome then "out/index.html" else "out/#{doc.id}/index.html"
    html = renderer.render "#{doc.layout}",
      attr: doc
      parent: parent doc, docs
      children: children doc, docs
      sidenav: sidenav doc, docs
      content: doc.__content
    fs.outputFile dest, html, (err) ->
      throw err if err
  sitemap()
  fs.writeFileSync "search.json", JSON.stringify(index.toJSON())
  fs.writeFileSync "results.json", JSON.stringify(results)
