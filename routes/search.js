// var context = require("search-context");
var es = require("elasticsearch");

var client = new es.Client({
  host: "http://localhost:9200"
});

module.exports = function(req, res) {
  var query = { index: "tests" };
  if (req.body.type) query.type = req.body.type;
  if (req.body.page) query.from = (req.body.page - 1) * 10;
  if (req.body.q) {
    query.q = req.body.q;
    client.search(query, function(err, data) {
      if (err) throw err;
      res.send(data.hits);
    });
  }
};
