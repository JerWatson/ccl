var qs = require("querystring");

var query = qs.parse(window.location.search.slice(1));
var $search = $("#search");
var $container = $("<div/>");
var $options = $("<div class='row search-options'/>");

var buildFilters = function(data) {
  var $container = $("<div class='col-sm-6'/>");
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
  var page = parseInt(query.page || 1);
  var pages = Math.ceil(data.total / 10);
  var $container = $("<div class='col-sm-6 text-right form-inline'/>");
  var $pagination = $("<select class='form-control' style='margin:20px 0;'/>");
  var $firstPage = $("<button class='btn btn-default' title='First Page'><i class='fa fa-angle-double-left'></i></button>");
  var $prevPage = $("<button class='btn btn-default' title='Previous Page'><i class='fa fa-angle-left'></i></button>");
  var $nextPage = $("<button class='btn btn-default' title='Next Page'><i class='fa fa-angle-right'></i></button>");
  var $lastPage = $("<button class='btn btn-default' title='Last Page'><i class='fa fa-angle-double-right'></i></button>");
  for (var i = 1, len = pages; i <= len; i++) {
    $pagination.append("<option value='" + i +"'>" + i + "</option>");
  }
  $pagination.val(page).attr("selected", true);
  $pagination.on("change", function(e) {
    e.preventDefault();
    query.page = $(this).val();
    window.location.href = "/search/?" + qs.stringify(query);
  });
  if (page === 1) {
    $firstPage.addClass("disabled");
    $prevPage.addClass("disabled");
  } else {
    $firstPage.on("click", function(e) {
      e.preventDefault();
      query.page = 1;
      window.location.href = "/search/?" + qs.stringify(query);
    });
    $prevPage.on("click", function(e) {
      e.preventDefault();
      query.page = page - 1;
      window.location.href = "/search/?" + qs.stringify(query);
    });
  }
  if (page === pages) {
    $lastPage.addClass("disabled");
    $nextPage.addClass("disabled");
  } else {
    $lastPage.on("click", function(e) {
      e.preventDefault();
      query.page = pages;
      window.location.href = "/search/?" + qs.stringify(query);
    });
    $nextPage.on("click", function(e) {
      e.preventDefault();
      query.page = page + 1;
      window.location.href = "/search/?" + qs.stringify(query);
    });
  }
  $container.append($firstPage, "&nbsp;");
  $container.append($prevPage, "&nbsp;");
  $container.append($pagination, "&nbsp;");
  $container.append($nextPage, "&nbsp;");
  $container.append($lastPage);
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
