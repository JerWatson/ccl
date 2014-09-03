var async = require("async");
var cheerio = require("cheerio");
var glob = require("glob");
var fs = require("fs-extra");
var Pdf = require("pdftotextjs");
var ProgressBar = require("progress");
var sql = require("mssql");
var yaml = require("yaml-front-matter");
var config = require("../config");

var connection = new sql.Connection(config.tims, function(err) {
  if (err) return done(err);
});

var extract = "EXEC sp_ExtractForCCL @code='', @q='', @key=''";

var unique = function(xs) {
  return xs.filter(function(x, i, xs) {
    return xs.indexOf(x) === i;
  });
};

var testIDs = function(done) {
  var req = new sql.Request(connection);
  req.query(extract, function(err, xs) {
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

var testDetail = function(id) {
  return "EXEC sp_GetTestDetailByTestID @testId=" + id + ", @site='reflab'";
};

var tests = function(ids, done) {
  var bar = new ProgressBar("tests: [:bar] :percent :elapseds :total", {
    total: ids.length
  });
  async.map(ids, function(id, done) {
    var req = new sql.Request(connection);
    req.query(testDetail(id), function(err, xs) {
      if (err) return done(err);
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
      bar.tick();
      done(null, item);
    });
  }, function(err, res) {
    if (err) return done(err);
    done(null, res);
  });
};

var loadDocs = function(done) {
  glob("src/documents/**/*.html", function(err, xs) {
    if (err) return done(err);
    async.map(xs, function(x, done) {
      done(null, yaml.loadFront(fs.readFileSync(x, "utf8")));
    }, function(err, res) {
      if (err) return done(err);
      done(null, res);
    })
  })
};

var trim = function(str) {
  return str.replace(/\s+/g, " ").trim();
};

var parseDocs = function(xs, done) {
  var bar = new ProgressBar("docs: [:bar] :percent :elapseds :total", {
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
  })
};

var pdfs = function(done) {
  glob("src/assets/pdfs/**/*.pdf", function(err, xs) {
    var bar = new ProgressBar("pdfs: [:bar] :percent :elapseds :total", {
      total: xs.length
    });
    async.map(xs, function(x, done) {
      var pdf = new Pdf(x);
      pdf.getText(function(err, text) {
        if (err) return done(err);
        var ref = x.split("/");
        var title = ref[ref.length - 1];
        var item = {
          title: title,
          text: trim(text),
          type: "pdf",
          url: x.replace("src/", "")
        };
        bar.tick();
        done(null, item);
      });
    }, function(err, res) {
      if (err) return done(err);
      done(null, res);
    });
  });
};

async.parallel([
  function(done) {
    async.waterfall([
      function(done) {
        testIDs(done);
      },
      function(ids, done) {
        tests(ids, done);
      }
    ], done);
  },
  function(done) {
    async.waterfall([
      function(done) {
        loadDocs(done);
      },
      function(docs, done) {
        parseDocs(docs, done);
      }
    ], done);
  },
  function(done) {
    pdfs(done);
  }
], function(err, res) {
  if (err) throw err;
  connection.close();
  results = [].concat.apply([], res);
  fs.outputFileSync("index.json", JSON.stringify(results));
});
