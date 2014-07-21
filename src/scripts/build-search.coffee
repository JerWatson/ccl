qs = require "querystring"

module.exports = (data) ->
  search = $("#search")
  search.html("<div class='list-group'></div>")
  searchList = $("#search .list-group")
  pagination = $(".pagination")
  filter = $(".search-options .btn")
  query = qs.parse window.location.search.slice 1

  filter
    .filter (i) -> return $(this).val() is query.filter
    .addClass("active")

  filter.on "click", (e) ->
    e.preventDefault()
    query.filter = $(this).val()
    query.page = 1
    window.location.href = "/search/?#{qs.stringify(query)}"

  perPage = 10
  begin = (query.page-1) * perPage
  end = begin + perPage
  results = data.slice begin, end
  pages = data.length / perPage
  pages = if pages > 10 then 10 else pages
  if results.length
    for item in results
      if item.body.length > 200
        text = "#{item.body.slice(0, 200)}..."
      else
        text = item.body
      type = switch item.type
        when "page" then "fa fa-file"
        when "pdf" then "fa fa-file-pdf-o text-danger"
        when "test" then "fa fa-flask text-primary"
      searchList.append("
        <a href='/#{item.id}' class='list-group-item'>
          <div class='media'>
              <div class='pull-left'>
                <i class='#{type}'></i>
              </div>
              <div class='media-body'>
                <h4 class='media-heading'>
                  #{item.title}
                </h4>
                #{text}
              </div>
          </div>
        </a>")
    pagination.append("
      <li class='disabled'><a href='#'>&laquo;</a></li>
    ")
    for i in [1..pages]
      if "#{i}" is query.page
        pagination.append("
          <li class='active'><a href='#'>#{i}</a></li>
        ")
      else
        pagination.append("
          <li><a href='#' class='btn-page'>#{i}</a></li>
        ")
    pagination.append("
      <li class='disabled'><a href='#'>&raquo;</a></li>
    ")
    $(".btn-page").on "click", (e) ->
      e.preventDefault()
      self = $(this)
      query.page = self.text()
      window.location.href = "/search/?#{qs.stringify(query)}"
    $(".pagination .disabled a").on "click", (e) ->
      e.preventDefault()
    search.prepend("<h5>Results for \"#{query.q}\".")
  else if not query.q
    search.append("<h5>Please enter search term.</h5>")
  else if not results.length
    search.append("<h5>No results found.</h5>")
  return
