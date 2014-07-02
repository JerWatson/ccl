cheerio = require "cheerio"
ect = require "ect"
fs = require "fs-extra"
glob = require "glob"
lunr = require "lunr"
sm = require "sitemap"
yaml = require "yaml-front-matter"

siteIndex = {}

searchIndex = lunr ->
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

format = (xs) ->
  unique breakHyphens removeSpaces notEmpty xs

search = (xs) ->
  xs.forEach (x) ->
    html = cheerio.load x.__content,
      normalizeWhitespace: true
    text = html("*")
      .map -> html(this).text().trim()
      .toArray()
    item =
      title: x.title
      body: format(text).join(" ")
      id: x.id
    searchIndex.add item
    siteIndex[item.id] = item
  fs.outputFileSync "search.json", JSON.stringify searchIndex.toJSON()
  fs.outputFileSync "results.json", JSON.stringify siteIndex

parent = (y, xs) ->
  xs.filter (x) ->
    x.id is y.parent

children = (y, xs) ->
  xs.filter (x) ->
    x.parent is y.id

sidenav = (y, xs) ->
  if y.isParent
    xs.filter (x) ->
      x.id is y.id or x.parent is y.id
  else if y.parent
    xs.filter (x) ->
      x.id is y.parent or x.parent is y.parent
  else []

render = (xs) ->
  xs.forEach (x) ->
    dest = if x.isHome then "out/index.html" else "out/#{x.id}/index.html"
    html = renderer.render "#{x.layout}",
      attr: x
      parent: parent x, xs
      children: children x, xs
      sidenav: sidenav x, xs
      content: x.__content
    fs.outputFileSync dest, html

sitemap = (xs) ->
  xs.forEach (x) ->
    site.add url: x.url unless x.id is "404"
  fs.outputFileSync "out/sitemap.xml", site

build = (xs) ->
  search xs
  render xs
  sitemap xs

glob "src/documents/**/*.html", (err, xs) ->
  build xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
