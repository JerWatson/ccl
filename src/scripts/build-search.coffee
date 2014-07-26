qs = require "querystring"

query = qs.parse window.location.search.slice 1
searchContainer = $("#search")
search = $("<div/>")
options = $("<div class='row search-options'/>")

buildFilters = (data) ->
  filtersContainer = $("<div class='col-md-6'/>")
  filters = $("<div class='btn-group' data-toggle='buttons'/>")
  filters.append "
    <label class='btn btn-default'>
      <input type='radio' name='options' id='all' value=''> All
    </label>
    <label class='btn btn-default'>
      <input type='radio' name='options' id='test' value='test'> Tests
    </label>
    <label class='btn btn-default'>
      <input type='radio' name='options' id='pdf' value='pdf'> Documents
    </label>
    <label class='btn btn-default'>
      <input type='radio' name='options' id='page' value='page'> Pages
    </label>"
  if data.query.filter
    type = data.query.filter.type[0]
    filters.find("##{type}").parent().addClass("active")
  else
    filters.find("#all").parent().addClass("active")
  filters.find("label").on "click", (e) ->
    e.preventDefault()
    query.filterBy = $(this).children().val()
    query.page = 1
    window.location.href = "/search/?#{qs.stringify query}"
  filtersContainer.append filters
  options.append filtersContainer

buildPagination = (data) ->
  paginationContainer = $("<div class='col-md-6 text-right'/>")
  pagination = $("<ul class='pagination'/>")
  page = (parseInt(data.query.offset) + data.query.pageSize) / data.query.pageSize
  if data.totalHits < 100
    pages = Math.ceil data.totalHits / data.query.pageSize
  for n in [1..pages or 10]
    if "#{n}" is "#{page}"
      pagination.append "<li class='active'><a href='#'>#{n}</a></li>"
    else
      pagination.append "<li><a href='#'>#{n}</a></li>"
  pagination.find("a").on "click", (e) ->
    e.preventDefault()
    query.page = $(this).text()
    window.location.href = "/search/?#{qs.stringify query}"
  paginationContainer.append pagination
  options.append paginationContainer

buildResults = (data) ->
  results = $("<div class='list-group'/>")
  for result in data.hits
    doc = result.document
    type = switch doc.type[0]
      when "page" then "fa fa-file"
      when "pdf" then "fa fa-file-pdf-o text-danger"
      when "test" then "fa fa-flask text-primary"
      else ""
    results.append "
      <a href='/#{doc.id}' class='list-group-item'>
        <div class='media'>
          <div class='pull-left'>
            <i class='#{type}'></i>
          </div>
          <div class='media-body'>
            <h4 class='media-heading'>
              #{doc.title}
            </h4>
            #{doc.teaser}
          </div>
        </div>
      </a>"
  search.append options
  search.append "<h5>Results for \"#{data.query.query.join " "}\".</h5>"
  search.append results

buildSearch = (data) ->
  buildFilters data
  buildPagination data
  buildResults data

module.exports = (data) ->
  console.log data
  if data.hits?.length
    buildSearch data
    searchContainer.html search
  else if not data.query
    searchContainer.html "<h5>Please enter search term.</h5>"
  else
    searchContainer.html "<h5>No results found.</h5>"
  return
