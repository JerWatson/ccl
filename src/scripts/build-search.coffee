# context = require "search-context"
qs = require "querystring"

query = qs.parse window.location.search.slice 1
$searchContainer = $("#search")
$search = $("<div/>")
$options = $("<div class='row search-options'/>")

buildFilters = (data) ->
  $filtersContainer = $("<div class='col-md-6'/>")
  $filters = $("<div class='btn-group' data-toggle='buttons'/>")
  $filters.append "
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
  if query.type
    type = query.type
    $filters.find("##{type}").parent().addClass("active")
  else
    $filters.find("#all").parent().addClass("active")
  $filters.find("label").on "click", (e) ->
    e.preventDefault()
    query.type = $(this).children().val()
    query.page = 1
    window.location.href = "/search/?#{qs.stringify query}"

  $filtersContainer.append $filters
  $options.append $filtersContainer

buildPagination = (data) ->
  $paginationContainer = $("<div class='col-md-6 text-right'/>")
  $pagination = $("<ul class='pagination'/>")
  page = query.page or 1

  if data.total < 100
    pages = Math.ceil data.total / 10

  $pagination.append "<li class='disabled'><span>&laquo;</span></li>"
  for n in [1..pages or 10]
    if "#{n}" is "#{page}"
      $pagination.append "<li class='active'><a href='#'>#{n}</a></li>"
    else
      $pagination.append "<li><a href='#'>#{n}</a></li>"
  $pagination.append "<li class='disabled'><span>&raquo;</span></li>"

  $pagination.find("a").on "click", (e) ->
    e.preventDefault()
    query.page = $(this).text()
    window.location.href = "/search/?#{qs.stringify query}"

  $paginationContainer.append $pagination
  $options.append $paginationContainer

buildResults = (data) ->
  $results = $("<div class='list-group'/>")

  for result in data.hits
    item = result._source
    type = switch result._type
      when "page" then "fa fa-file"
      when "pdf" then "fa fa-file-pdf-o text-danger"
      when "test" then "fa fa-flask text-primary"
      else ""
    # text = context item.text, query.q.split(" "), 250, (str) ->
    #   "<strong>#{str}</strong>"
    $results.append "
      <a href='/#{item.url}' class='list-group-item'>
        <div class='media'>
          <div class='pull-left'>
            <i class='#{type}'></i>
          </div>
          <div class='media-body'>
            <h4 class='media-heading'>
              #{item.title}
            </h4>
            #{item.text}
          </div>
        </div>
      </a>"

  $search.append $options
  $search.append "<h5>Results for \"#{query.q}\".</h5>"
  $search.append $results

buildSearch = (data) ->
  buildFilters data
  buildPagination data
  buildResults data

module.exports = (data) ->
  if data.hits?.length
    buildSearch data
    $searchContainer.html $search
  else
    str = "No results found for \"#{query.q}\""
    str += " filtered by \"#{query.type}\"" if query.type
    $searchContainer.html "<h5>#{str}.</h5>"
  return
