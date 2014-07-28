path = require "path"
ect = require "ect"
fs = require "fs-extra"
glob = require "glob"
{minify} = require "html-minifier"
sm = require "sitemap"
yaml = require "yaml-front-matter"

renderer = ect
  root: path.join __dirname, "../src/layouts"
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
    dest = switch
      when x.isHome then path.join __dirname, "../out/index.html"
      else path.join __dirname, "../out/#{x.id}/index.html"
    html = renderer.render "#{x.layout}",
      attr: x
      parent: parent x, xs
      children: children x, xs
      sidenav: sidenav x, xs
      content: x.__content
    fs.outputFileSync dest, minify html,
      collapseWhitespace: true
      conservativeCollapse: true
      minifyJS: true
      minifyCSS: true

sitemap = (xs) ->
  xs.forEach (x) ->
    site.add url: x.url unless x.id is "404"
  fs.outputFileSync path.join(__dirname, "../out/sitemap.xml"), site

build = (xs) ->
  render xs
  sitemap xs

glob "src/documents/**/*.html", (err, xs) ->
  build xs.map (x) ->
    file = path.join __dirname, "../#{x}"
    yaml.loadFront fs.readFileSync file, "utf8"
