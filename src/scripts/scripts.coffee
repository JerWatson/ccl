qs = require "querystring"
url = require "url"
buildSearch = require "./build-search"
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

siteSearch = (href) ->
  $.ajax
    type: "POST"
    url: href
    data: qs.parse window.location.search.slice 1
    dataType: "json"
    success: (data) -> buildSearch data
    error: (err, text, status) -> buildSearch text
  return

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

switch (url.parse window.location.href).pathname
  when "/test-list/" then testSearch "/test-list"
  when "/test/" then testSearch "/test"
  when "/search/" then siteSearch "/search"
