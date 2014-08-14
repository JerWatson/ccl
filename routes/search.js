var context = require("search-context");
var es = require("elasticsearch");

var client = new es.Client({
  host: "http://localhost:9200"
});

module.exports = function(req, res) {
  var query = {};
  if (req.body.q) query.q = req.body.q;
  if (req.body.type) query.type = req.body.type;
  if (req.body.page) query.from = (req.body.page - 1) * 10;
  if (req.body.q) {
    client.search(query, function(err, data) {
      data.hits.hits.forEach(function(hit) {
        hit._source.text = context(hit._source.text, req.body.q.split(" "), 250, function(str) {
          return "<strong>" + str + "</strong>";
        });
      });
      res.send(data.hits);
    });
  }
};
