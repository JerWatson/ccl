var qs = require("querystring");

var query = qs.parse(window.location.search.slice(1));
var $search = $("#search");
var $container = $("<div/>");
var $options = $("<div class='row search-options'/>");

var buildFilters = function(data) {
  var $container = $("<div class='col-md-6'/>");
  var $filters = $("<div class='btn-group' data-toggle='buttons'/>");
  var html = [
    "<label class='btn btn-default'>",
      "<input type='radio' name='options' id='all' value=''> All",
    "</label>",
    "<label class='btn btn-default'>",
      "<input type='radio' name='options' id='test' value='test'> Tests",
    "</label>",
    "<label class='btn btn-default'>",
      "<input type='radio' name='options' id='pdf' value='pdf'> Documents",
    "</label>",
    "<label class='btn btn-default'>",
      "<input type='radio' name='options' id='page' value='page'> Pages",
    "</label>",
  ].join("");
  $filters.append(html);
  if (query.type) {
    var type = query.type;
    $filters.find("#" + type).parent().addClass("active");
  } else {
    $filters.find("#all").parent().addClass("active");
  }
  $filters.find("label").on("click", function(e) {
    e.preventDefault();
    query.type = $(this).children().val();
    query.page = 1;
    window.location.href = "/search/?" + qs.stringify(query);
  });
  $container.append($filters);
  $options.append($container);
};

var buildPagination = function(data) {
  var $container = $("<div class='col-md-6 text-right'/>");
  var $pagination = $("<ul class='pagination'/>");
  var page = query.page || 1;
  if (data.total < 100) {
    var pages = Math.ceil(data.total / 10);
  }
  $pagination.append("<li class='disabled'><span>&laquo;</span></li>");
  for (var i = 1, len = pages || 10; i <= len; i++) {
    if (i.toString() === page.toString()) {
      $pagination.append("<li class='active'><a href='#'>" + i + "</a></li>");
    } else {
      $pagination.append("<li><a href='#'>" + i + "</a></li>");
    }
  }
  $pagination.append("<li class='disabled'><span>&raquo;</span></li>");
  $pagination.find("a").on("click", function(e) {
    e.preventDefault();
    query.page = $(this).text();
    window.location.href = "/search/?" + qs.stringify(query);
  });
  $container.append($pagination);
  $options.append($container);
};

var buildResults = function(data) {
  var $results = $("<div class='list-group'/>");
  for (var i = 0, len = data.hits.length; i < len; i++) {
    var result = data.hits[i];
    var item = result._source;
    var icon = "";
    if (result._type === "page") icon = "fa fa-file";
    if (result._type === "pdf")  icon = "fa fa-file-pdf-o text-danger";
    if (result._type === "test") icon = "fa fa-flask text-primary";
    var html = [
      "<a href='/" + item.url + "' class='list-group-item'>",
        "<div class='media'>",
          "<div class='pull-left'>",
            "<i class='" + icon + "'></i>",
          "</div>",
          "<div class='media-body'>",
            "<h4 class='media-heading'>" + item.title + "</h4>",
            item.text,
          "</div>",
        "</div>",
      "</a>"
    ].join("");
    $results.append(html);
  }
  $container.append($options);
  $container.append("<h5>Results for \"" + query.q + "\".</h5>");
  $container.append($results);
};

var buildSeasrch = function(data) {
  buildFilters(data);
  buildPagination(data);
  buildResults(data);
};

module.exports = function(data) {
  if (data.hits && data.hits.length) {
    buildSeasrch(data);
    $search.html($container);
  } else {
    var str = "No results found for \"" + query.q + "\"";
    if (query.type) {
      str += " filtered by \"" + query.type + "\"";
    }
    $search.html("<h5>" + str + ".</h5>");
  }
};
