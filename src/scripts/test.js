module.exports = function(data) {
  var source = $("#search-template").html();
  var template = doT.template(source);
  var html = template(data);
  $("#search").html(html);
};
