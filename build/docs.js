var ect = require("ect");
var fs = require("fs-extra");
var glob = require("glob");
var minify = require("html-minifier").minify;
var path = require("path");
var ProgressBar = require("progress");
var sm = require("sitemap");
var yaml = require("yaml-front-matter");

var renderer = ect({
  root: path.join(__dirname, "../src/layouts"),
  ext: ".ect"
});

var site = sm.createSitemap({
  hostname: "http://clevelandcliniclabs.com"
});

var parent = function(y, xs) {
  return xs.filter(function(x) {
    return x.id === y.parent;
  });
};

var children = function(y, xs) {
  return xs.filter(function(x) {
    return x.parent === y.id;
  });
};

var sidenav = function(y, xs) {
  if (y.isParent) {
    return xs.filter(function(x) {
      return x.id === y.id || x.parent === y.id;
    });
  } else if (y.parent) {
    return xs.filter(function(x) {
      return x.id === y.parent || x.parent === y.parent;
    });
  } else {
    return [];
  }
};

var render = function(xs) {
  var bar = new ProgressBar("[:bar] :percent :elapseds", {
    incomplete: " ",
    total: xs.length
  });
  xs.forEach(function(x) {
    var dest = x.isHome
      ? path.join(__dirname, "../out/index.html")
      : path.join(__dirname, "../out/" + x.id + "/index.html");
    var html = renderer.render(x.layout, {
      attr: x,
      parent: parent(x, xs),
      children: children(x, xs),
      sidenav: sidenav(x, xs),
      content: x.__content
    });
    fs.outputFileSync(dest, minify(html, {
      collapseWhitespace: true,
      conservativeCollapse: true,
      minifyJS: true,
      minifyCSS: true
    }));
    bar.tick();
  });
};

var sitemap = function(xs) {
  xs.forEach(function(x) {
    if (x.id !== "404") {
      site.add({url: x.url});
    }
  });
  fs.outputFileSync(path.join(__dirname, "../out/sitemap.xml"), site);
};

var build = function(xs) {
  render(xs);
  sitemap(xs);
};

glob("src/documents/**/*.html", function(err, xs) {
  if (err) throw err;
  build(xs.map(function(x) {
    var file = path.join(__dirname, "../" + x);
    return yaml.loadFront(fs.readFileSync(file, "utf8"));
  }));
});
