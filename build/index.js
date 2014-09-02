var cheerio = require("cheerio");
var glob = require("glob");
var fs = require("fs-extra");
var Pdf = require("pdftotextjs");
var ProgressBar = require("progress");
var sql = require("mssql");
var yaml = require("yaml-front-matter");
var config = require("../config");

var index = [];
var pdfs = [];

var test = function(id) {
  return "EXEC sp_GetTestDetailByTestID @testId=" + id + ", @site='reflab'";
};

var addTests = function(ids) {
  var bar = new ProgressBar("tests: [:bar] :percent :elapseds", {
    incomplete: " ",
    total: ids.length,
    callback: function() {
      connection.close();
      fs.outputFileSync("index.json", JSON.stringify(index));
    }
  });
  var connection = new sql.Connection(config.tims, function(err) {
    if (err) throw err;
  });
  var request = new sql.Request(connection);
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
      bar.tick();
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
  var bar = new ProgressBar("pdfs:  [:bar] :percent :elapseds", {
    incomplete: " ",
    total: xs.length,
    callback: getTests()
  });
  xs.forEach(function(x) {
    var pdf = new Pdf("src" + x);
    pdf.getText(function(err, text) {
      var ref = x.split("/");
      var title = ref[ref.length - 1];
      var item = {
        title: title,
        text: trim(text),
        type: "pdf",
        url: x.slice(1)
      };
      index.push(item);
      bar.tick();
    });
  });
};

var addDocs = function(xs) {
  var bar = new ProgressBar("docs:  [:bar] :percent :elapseds", {
    incomplete: " ",
    total: xs.length,
    callback: function() {
      addPdfs(pdfs)
    }
  });
  xs.forEach(function(x) {
    var $ = cheerio.load(x.__content, {
      normalizeWhitespace: true
    });
    $("a").filter(function() {
      var href = $(this).attr("href");
      return !!href.match(/^\/assets.*\.pdf$/);
    }).each(function() {
      pdfs.push($(this).attr("href"));
    });
    var item = {
      title: x.title,
      text: trim($.root().text()),
      type: "page",
      url: x.id
    };
    if (x.id !== "404") index.push(item);
    bar.tick();
  });
};

glob("src/documents/**/*.html", function(err, xs) {
  if (err) throw err;
  addDocs(xs.map(function(x) {
    return yaml.loadFront(fs.readFileSync(x, "utf8"));
  }));
});
