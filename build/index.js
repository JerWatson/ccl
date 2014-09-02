var cheerio = require("cheerio");
var glob = require("glob");
var fs = require("fs-extra");
var Pdf = require("pdftotextjs");
var sql = require("mssql");
var yaml = require("yaml-front-matter");
var config = require("../config");

var index = [];

var test = function(id) {
  return "EXEC sp_GetTestDetailByTestID @testId=" + id + ", @site='reflab'";
};

var addTests = function(ids) {
  var connection = new sql.Connection(config.tims, function(err) {
    if (err) throw err;
  });
  var request = new sql.Request(connection);
  var pending = ids.length;
  ids.forEach(function(id) {
    request.query(test(id), function(err, xs) {
      if (err) throw err;
      var x = xs[0];
      var item = {
        title: x.PrimaryName,
        alias: x.Alias,
        lis: x.LISCode,
        lfs: x.LFSCode,
        cpt: x.CPTCode,
        text: x.ClinicalInfo,
        type: "test",
        url: "test/?ID=" + id
      };
      index.push(item);
      if (!--pending) {
        connection.close();
        fs.outputFileSync("index.json", JSON.stringify(index));
      }
    });
  });
};

var extract = function() {
  return "EXEC sp_ExtractForCCL @code='', @q='', @key=''";
};

var unique = function(xs) {
  return xs.filter(function(x, i, xs) {
    return xs.indexOf(x) === i;
  });
};

var getTests = function() {
  var connection = new sql.Connection(config.tims, function(err) {
    if (err) throw err;
  });
  var request = new sql.Request(connection);
  request.query(extract(), function(err, xs) {
    if (err) throw err;
    connection.close();
    var current = xs.filter(function(x) {
      return !x.DeletedOn && (x.DictIntendedForID === 2 || x.DictIntendedForID === 3);
    });
    addTests(unique(current.map(function(x) {
      return x.ID;
    })));
  });
};

var trim = function(str) {
  return str.replace(/\s+/g, " ").trim();
};

var addPdfs = function(xs) {
  xs.forEach(function(x) {
    var pdf = new Pdf("src" + x);
    pdf.getText(function(err, text) {
      if (err) throw err;
      var ref = x.split("/");
      var title = ref[ref.length - 1];
      var item = {
        title: title,
        text: trim(text),
        type: "pdf",
        url: x.slice(1)
      };
      index.push(item);
    });
  });
};

var addDocs = function(xs) {
  var pending = xs.length;
  xs.forEach(function(x) {
    var $ = cheerio.load(x.__content, {
      normalizeWhitespace: true
    });
    var pdfs = $("a").filter(function() {
      var href = $(this).attr("href");
      return !!href.match(/^\/assets.*\.pdf$/);
    }).map(function() {
      return $(this).attr("href");
    }).toArray();
    var item = {
      title: x.title,
      text: trim($.root().text()),
      type: "page",
      url: x.id
    };
    if (x.id !== "404") {
      index.push(item);
    }
    addPdfs(pdfs);
    if (!--pending) {
      getTests();
    }
  });
};

glob("src/documents/**/*.html", function(err, xs) {
  if (err) throw err;
  addDocs(xs.map(function(x) {
    return yaml.loadFront(fs.readFileSync(x, "utf8"));
  }));
});
