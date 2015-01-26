var url = "http://portals.clevelandclinic.org";
var path = "/reflab/SearchDetails/tabid/4698/Default.aspx";
var location = url + path;
var $search = $("#search");

module.exports = function(data) {
  var $data = $.parseHTML(data);
  var $html = $("<div/>");
  $html.html($data);
  $html.find("title").remove();
  $html.find("hr + table").remove();
  $html.find("hr").remove();
  $html.find(".headerRule").remove();
  $html.find("input[type='button']").remove();
  $html.find("a[href='#']").remove();
  $html.find("table").addClass("table table-search table-hover");
  $html.find(".NormalResults a, a.NormalResults").each(function() {
    this.href = this.href.replace(location, "/test/");
    $(this).removeAttr("target");
  });
  $html.find("tr").css({"background-color": "transparent"});
  $search.html($html);
};
