path = require "path"
ect = require "ect"
fs = require "fs-extra"
glob = require "glob"
sm = require "sitemap"
yaml = require "yaml-front-matter"

renderer = ect
  root: path.resolve __dirname, "..", "src/layouts"
  ext: ".ect"

site = sm.createSitemap
  hostname: "http://clevelandcliniclabs.com"

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
  render xs
  sitemap xs

glob "src/documents/**/*.html", (err, xs) ->
  build xs.map (x) ->
    yaml.loadFront fs.readFileSync x, "utf8"
