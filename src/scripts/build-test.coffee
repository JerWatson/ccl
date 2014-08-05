url = "http://portals.clevelandclinic.org"
path = "/reflab/SearchDetails/tabid/4698/Default.aspx"
location = "#{url}#{path}"
$search = $("#search")

module.exports = (data) ->
  $data = $.parseHTML data
  $html = $("<div/>")
  $html.html $data
  $html.find("title").remove()
  $html.find("hr + table").remove()
  $html.find("hr").remove()
  $html.find(".headerRule").remove()
  $html.find("input[type='button']").remove()
  $html.find("a[href='#']").remove()
  $html.find("table").addClass("table table-search table-hover")
  $html.find("a.NormalResults").each ->
    this.href = this.href.replace location, "/test/"
  $html.find("tr").css({"background-color":"transparent"})
  $search.html $html
