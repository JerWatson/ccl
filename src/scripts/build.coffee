location = "http://portals.clevelandclinic.org/reflab/SearchDetails/tabid/4698/Default.aspx"

module.exports = (data) ->
  html = $.parseHTML data
  search = $("#search")
  search.html html
  search.find("title").remove()
  search.find("script").remove()
  search.find("link").remove()
  search.find("hr + table").remove()
  search.find("hr").remove()
  search.find(".headerRule").remove()
  search.find("input[type='button']").remove()
  search.find("a[href='#']").remove()
  search.find("table").addClass("table table-search table-hover")
  search.find("a.NormalResults").addClass("test-detail")
  $(".test-detail").each ->
    this.href = this.href.replace location, "/test/"
  search.find("tr").css({"background-color":"transparent"})
  search.wrapInner("<div class='results'></div>")
