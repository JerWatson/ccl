qs = require "querystring"
url = require "url"
buildSearch = require "./build-search"
buildTest = require "./build-test"

# IE8 polyfill
unless String.prototype.trim
  String.prototype.trim = ->
    this.replace /^\s+|\s+$/g, ""

# IE8 polyfill
unless Object.keys
  Object.keys = (o) ->
    if o isnt Object(o)
      throw new TypeError "Object.keys called on a non-object"
    k for own k of o

$("#test-search-form").on "submit", (e) ->
  e.preventDefault()
  if $("#test-q").val()
    window.location.href = "/test-list/?#{$(this).serialize()}"
  return

$("#test-key").on "change", (e) ->
  e.preventDefault()
  window.location.href = "/test-list/?key=#{$(this).val()}"
  return

$("#search-form").on "submit", (e) ->
  e.preventDefault()
  val = $("#search-input").val()
  window.location.href = "/search/?q=#{val}" if val
  return

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

  self.find(".alert").remove()
  self.find("input, textarea").each ->
    $(this).parent().removeClass("has-error")

  faults = self.find("input, textarea").filter ->
    $(this).data("required") and $(this).val() is ""
  .parent().addClass("has-error")

  unless $("#subject").val()
    unless faults.length
      $.ajax
        type: "POST"
        url: "/mail"
        data: self.serialize()
        dataType: "json"
        beforeSend: ->
          self.html "
            <div class='loading'>
              <img src='/assets/imgs/layout/loading.gif'>
            </div>"
        success: (data) ->
          self.html "<p>Thank you!</p>"
        error: (err, text, status) ->
          self.html "
            <p>
              Error: Please contact
              <a href='mailto:ClientServices@ccf.org'>Client Services</a>
              if the problem persists
            </p>"
    else
      self.find("button").before "
        <div class='alert alert-danger'>
          Please fill out all required fields.
        </div>"
  else
    self.html "<p>Thank you!</p>"
  return

$(".info").tooltip()
$(".carousel").carousel({interval: false})

switch (url.parse window.location.href).pathname
  when "/test-list/" then testSearch "/test-list"
  when "/test/" then testSearch "/test"
  when "/search/" then siteSearch "/search"
