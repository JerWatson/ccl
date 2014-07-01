qs    = require "querystring"
url   = require "url"
build = require "./build"

# IE8 polyfill
if typeof String.prototype.trim isnt "function"
  String.prototype.trim = -> this.replace(/^\s+|\s+$/g, "")

# IE8 polyfill
if not Object.keys
  Object.keys = (o) ->
    throw new TypeError "Object.keys called on a non-object" if o isnt Object(o)
    r = []
    for own k of o
      r.push k
    r

$("#search-form").on "submit", (e) ->
  e.preventDefault()
  empty = $("#q").val() is ""
  window.location.href = "/search-list/?" + $(this).serialize() if not empty
  return

$("#key").on "change", (e) ->
  e.preventDefault()
  window.location.href = "/search-list/?key=" + $(this).val()
  return

search = (href) ->
  $.ajax
    type: "GET"
    url: href
    data: qs.parse window.location.search.slice 1
    dataType: "json"
    success: (data) -> build data
    error: (err, text, status) -> build text
  return

page = url.parse window.location.href

switch page.pathname
  when "/search-list/"   then search "/test-list"
  when "/search-detail/" then search "/test-detail"

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
