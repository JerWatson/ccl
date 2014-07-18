qs = require "querystring"
url = require "url"
buildTest = require "./build-test"

# IE8 polyfill
if typeof String.prototype.trim isnt "function"
  String.prototype.trim = -> this.replace /^\s+|\s+$/g, ""

# IE8 polyfill
if not Object.keys
  Object.keys = (o) ->
    if o isnt Object(o)
      throw new TypeError "Object.keys called on a non-object"
    k for own k of o

$("#search-form").on "submit", (e) ->
  e.preventDefault()
  empty = $("#q").val() is ""
  if not empty
    window.location.href = "/test-list/?#{$(this).serialize()}"
  return

$("#key").on "change", (e) ->
  e.preventDefault()
  window.location.href = "/test-list/?key=#{$(this).val()}"
  return

$("#test-search-form").on "submit", (e) ->
  e.preventDefault()
  val = $("#test-search-input").val()
  empty = val is ""
  if not empty
    window.location.href = "/search/?q=#{val}&filter=all&page=1"

testSearch = (href) ->
  $.ajax
    type: "POST"
    url: href
    data: qs.parse window.location.search.slice 1
    dataType: "json"
    success: (data) -> buildTest data
    error: (err, text, status) -> buildTest text
  return

buildSearch = (data) ->
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

siteSearch = (href) ->
  $.ajax
    type: "POST"
    url: href
    data: qs.parse window.location.search.slice 1
    dataType: "json"
    success: (data) -> buildSearch data
    error: (err, text, status) -> buildSearch text
  return

page = url.parse window.location.href

switch page.pathname
  when "/test-list/" then testSearch "/test-list"
  when "/test/" then testSearch "/test"
  when "/search/" then siteSearch "/search"

$(".mail-form").on "submit", (e) ->
  e.preventDefault()
  self = $(this)
  if $("#subject").val() is "" or $("#subject").val() is undefined
    $.ajax
      type: "POST"
      url: "/mail"
      data: self.serialize()
      dataType: "json"
      success: (data) -> self.html "<p>Thank you!</p>"
      error: (err, text, status) ->
        self.html "<p>Error: Please contact
          <a href='mailto:ClientServices@ccf.org'>Client Services</a>
          if the problem persists</p>"
  else
    self.html "<p>Thank you!</p>"
  return

$(".info").tooltip()
