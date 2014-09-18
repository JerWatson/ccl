var async = require("async");
var Bar = require("progress");
var cheerio = require("cheerio");
var glob = require("glob");
var fs = require("fs-extra");
var Pdf = require("pdftotextjs");
var sql = require("mssql");
var yaml = require("yaml-front-matter");
var config = require("../config");

var connection = new sql.Connection(config.tims, function(err) {
  if (err) throw err;
});

var unique = function(xs) {
  return xs.filter(function(x, i, xs) {
    return xs.indexOf(x) === i;
  });
};

var trim = function(str) {
  return str.replace(/\s+/g, " ").trim();
};

var extractTests = "EXEC sp_ExtractForCCL @code='', @q='', @key=''";

var getTest = function(id) {
  return "EXEC sp_GetTestDetailByTestID @testId=" + id + ", @site='reflab'";
};

var barFmt = function(id) {
  return id + ": [:bar] :percent :elapseds :total";
};

var loadTests = function(done) {
  var req = new sql.Request(connection);
  req.query(extractTests, function(err, xs) {
    if (err) return done(err);
    done(null, unique(xs.filter(function(x) {
      var current = !x.DeletedOn;
      var intended = x.DictIntendedForID === 2 || x.DictIntendedForID === 3;
      return current && intended;
    }).map(function(x) {
      return x.ID;
    })));
  });
};

var parseTests = function(ids, done) {
  var bar = new Bar(barFmt("tests"), {
    total: ids.length
  });
  async.map(ids, function(id, done) {
    var req = new sql.Request(connection);
    req.stream = true;
    req.query(getTest(id));
    req.on("row", function(x) {
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
      bar.tick();
      done(null, item);
    });
    req.on("error", function(err) {
      done(err);
    });
  }, function(err, res) {
    if (err) return done(err);
    done(null, res);
  });
};

var indexTests = function(done) {
  async.waterfall([
    loadTests,
    parseTests
  ], done);
};

var loadDocs = function(done) {
  glob("src/documents/**/*.html", function(err, xs) {
    if (err) return done(err);
    async.map(xs, function(x, done) {
      done(null, yaml.loadFront(fs.readFileSync(x, "utf8")));
    }, function(err, res) {
      if (err) return done(err);
      done(null, res);
    });
  });
};

var parseDocs = function(xs, done) {
  var bar = new Bar(barFmt("docs"), {
    total: xs.length
  });
  async.map(xs, function(x, done) {
    var $ = cheerio.load(x.__content, {
      normalizeWhitespace: true
    });
    var item = {
      title: x.title,
      text: trim($.root().text()),
      type: "page",
      url: x.id
    };
    bar.tick();
    done(null, item);
  }, function(err, res) {
    if (err) return done(err);
    done(null, res);
  });
};

var indexDocs = function(done) {
  async.waterfall([
    loadDocs,
    parseDocs
  ], done);
};

var loadPdfs = function(done) {
  glob("src/assets/pdfs/**/*.pdf", function(err, xs) {
    if (err) return done(err);
    async.map(xs, function(x, done) {
      done(null, new Pdf(x));
    }, function(err, res) {
      if (err) return done(err);
      done(null, res);
    });
  });
};

var parsePdfs = function(xs, done) {
  var bar = new Bar(barFmt("pdfs"), {
    total: xs.length
  });
  async.map(xs, function(x, done) {
    x.getText(function(err, text) {
      if (err) return done(err);
      var path = x.options.additional[0];
      var ref = path.split("/");
      var title = ref[ref.length - 1];
      var item = {
        title: title,
        text: trim(text),
        type: "pdf",
        url: path.replace("src/", "")
      };
      bar.tick();
      done(null, item);
    });
  }, function(err, res) {
    if (err) return done(err);
    done(null, res);
  })
};

var indexPdfs = function(done) {
  async.waterfall([
    loadPdfs,
    parsePdfs
  ], done);
};

async.series([
  indexTests,
  indexDocs,
  indexPdfs
], function(err, res) {
  if (err) throw err;
  connection.close();
  results = [].concat.apply([], res);
  fs.outputFileSync("index.json", JSON.stringify(results));
});
