url = "http://portals.clevelandclinic.org"
path = "/reflab/SearchDetails/tabid/4698/Default.aspx"
location = "#{url}#{path}"
search = $("#search")

module.exports = (data) ->
  html = $.parseHTML data
  search.html html
  search.find("title").remove()
  search.find("hr + table").remove()
  search.find("hr").remove()
  search.find(".headerRule").remove()
  search.find("input[type='button']").remove()
  search.find("a[href='#']").remove()
  search.find("table").addClass("table table-search table-hover")
  search.find("a.NormalResults").each ->
    this.href = this.href.replace location, "/test/"
  search.find("tr").css({"background-color":"transparent"})
