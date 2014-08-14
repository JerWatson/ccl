var qs = require("querystring");
var url = require("url");
var buildSearch = require("./build-search");
var buildTest = require("./build-test");

// IE8 polyfill
if (!String.prototype.trim) {
  String.prototype.trim = function() {
    return this.replace(/^\s+|\s+$/g, "");
  };
}

// IE8 polyfill
if (!Object.keys) {
  Object.keys = function(o) {
    var hasProp = {}.hasOwnProperty;
    if (o !== Object(o)) {
      throw new TypeError("Object.keys called on a non-object");
    }
    var results = [];
    for (var k in o) {
      if (!hasProp.call(o, k)) continue;
      results.push(k);
    }
    return results;
  }
}

var testSearch = function(href) {
  $.ajax({
    type: "POST",
    url: href,
    data: qs.parse(window.location.search.slice(1)),
    dataType: "json",
    success: function(data) {
      buildTest(data);
    },
    error: function(err, text, status) {
      buildTest(text);
    }
  });
};

var siteSearch = function() {
  var query = qs.parse(window.location.search.slice(1));
  if (query.q) {
    $.ajax({
      type: "POST",
      url: "/search",
      data: query,
      dataType: "json",
      success: function(data) {
        console.log(data);
        buildSearch(data);
      },
      error: function(err, text, status) {
        console.log(err);
        buildSearch(text);
      }
    });
  } else {
    $("#search").html("<h5>Please enter search term.</h5>");
  }
};

$("#test-search-form").on("submit", function(e) {
  e.preventDefault();
  if ($("#test-q").val()) {
    window.location.href = "/test-list/?" + $(this).serialize();
  }
});

$("#test-key").on("change", function(e) {
  e.preventDefault();
  window.location.href = "/test-list/?key=" + $(this).val();
});

$("#search-form").on("submit", function(e) {
  e.preventDefault();
  var $val = $("#search-input").val();
  if ($val) {
    window.location.href = "/search/?q=" + $val;
  }
});

$(".mail-form").on("submit", function(e) {
  e.preventDefault();
  var $this = $(this);
  $this.find(".alert").remove();

  var $fields = $this.find("input, textarea");
  $fields.each(function() {
    $(this).parent().removeClass("has-error");
  });

  var faults = $fields.filter(function() {
    return $(this).data("required") && $(this).val() === "";
  }).parent().addClass("has-error");

  if (!$("#subject").val()) {
    if (!faults.length) {
      $.ajax({
        type: "POST",
        url: "/mail",
        data: $this.serialize(),
        dataType: "json",
        beforeSend: function() {
          $this.html(" \
            <div class='loading'> \
              <img src='/assets/imgs/layout/loading.gif'> \
            </div> \
          ");
        },
        success: function(data) {
          $this.html("<p>Thank you!</p>");
        },
        error: function(err, text, status) {
          $this.html(" \
            <p> \
              Error: Please contact \
              <a href='mailto:ClientServices@ccf.org'>Client Services</a> \
              if the problem persists. \
            </p> \
          ");
        }
      })
    } else {
      $this.find("button").before(" \
        <div class='alert alert-danger'> \
          Please fill out all required fields. \
        </div> \
      ");
    }
  } else {
    $this.html("<p>Thank you!</p>");
  }
});

$(".info").tooltip();
$(".carousel").carousel({interval: false});

var path = (url.parse(window.location.href)).pathname;
if (path === "/test-list/") testSearch("/test-list");
if (path === "/test/") testSearch("/test");
if (path === "/search/") siteSearch();
