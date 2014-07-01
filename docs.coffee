ect = require "ect"
fs = require "fs-extra"
glob = require "glob"
sm = require "sitemap"
yaml = require "yaml-front-matter"

renderer = ect
  root: "#{__dirname}/src/layouts"
  ext: ".ect"
  open: "{{"
  close: "}}"

sitemap = sm.createSitemap
  hostname: "http://clevelandcliniclabs.com"

getDocuments = (done) ->
  results = []
  glob "src/documents/**/*.html", (err, list) ->
    done err if err
    pending = list.length
    done null, results unless pending
    list.forEach (item) ->
      fs.readFile item, "utf8", (err, data) ->
        results.push yaml.loadFront data
        done null, results unless --pending

getParent = (page, list) ->
  list.filter (item) ->
    item.id is page.parent

getChildren = (page, list) ->
  list.filter (item) ->
    item.parent is page.id

getSidenav = (page, list) ->
  if page.isParent
    list.filter (item) ->
      item.id is page.id or item.parent is page.id
  else if page.parent
    list.filter (item) ->
      item.id is page.parent or item.parent is page.parent
  else []

getSitemap = ->
  glob "out/**/*.html", (err, list) ->
    throw err if err
    list.forEach (item) ->
      item = item.replace "out", ""
      sitemap.add url: item unless item is "/404/index.html"
    fs.outputFile "out/sitemap.xml", sitemap, (err) ->
      throw err if err

getDocuments (err, docs) ->
  throw err if err
  docs.forEach (doc) ->
    dest = if doc.isHome then "out/index.html" else "out/#{doc.id}/index.html"
    html = renderer.render "#{doc.layout}",
      attr: doc
      parent: getParent doc, docs
      children: getChildren doc, docs
      sidenav: getSidenav doc, docs
      content: doc.__content
    fs.outputFile dest, html, (err) ->
      throw err if err
  do getSitemap
