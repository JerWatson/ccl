qs = require "querystring"
express = require "express"
lunr = require "lunr"
mailer = require "nodemailer"
request = require "request"
search = require "./search.json"
results = require "./results.json"
{mail} = require "./settings.json"

app = express()
port = 3003
index = lunr.Index.load search
smtp = mailer.createTransport "SMTP",
  service: "Gmail"
  auth:
    user: mail.user
    pass: mail.pass

app.configure ->
  app.use express.urlencoded()
  app.use express.json()
  app.use express.static "#{__dirname}/out"
  app.use app.router

app.get "/search", (req, res) ->
  xs = index.search JSON.stringify req.query.q
  res.send JSON.stringify xs.map (x, i) ->
    results[x.ref]

app.get "/test-list", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestList.aspx?"
  query = qs.stringify req.query
  request "#{url}#{query}&site=reflab", (err, response, body) ->
    throw err if err
    res.send JSON.stringify body

app.get "/test-detail", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestDetail.aspx?"
  query = qs.stringify req.query
  request "#{url}#{query}&site=reflab", (err, response, body) ->
    throw err if err
    res.send JSON.stringify body

app.post "/mail", (req, res) ->
  content = ""
  for key, val of req.body
    unless val is "" or key is "Form" or key is "To"
      content += "<strong>#{key}</strong>: #{val}<br>"
  options =
    from: "Cleveland Clinic Laboratories <clevelandcliniclabs@gmail.com>"
    bcc: req.body.To
    subject: "#{req.body.Form} submitted"
    html: content
    generateTextFromHTML: true
  smtp.sendMail options, (err, response) ->
    throw err if err
    res.send JSON.stringify response.message

app.get "/TestDirectory/*", (req, res) -> res.redirect "/test-directory"
app.get "/Home/*", (req, res) -> res.redirect "/"
app.get "/AboutUs/NewReferenceLaboratory/*", (req, res) -> res.redirect "/about-us"
app.get "/Publications/PathologyResearch/*", (req, res) -> res.redirect "/publications"
app.get "/PoliciesandProcedures/*", (req, res) -> res.redirect "/policies-and-procedures"
app.get "/SearchResults/*", (req, res) -> res.redirect "/"
app.get "/ClientServices/ElectronicSupplyForm/*", (req, res) -> res.redirect "/forms/supply-order-form"
app.get "/ClientServices/*", (req, res) -> res.redirect "/contact-us/client-services"
app.get "/ClinicalPathology/*", (req, res) -> res.redirect "/clinical-pathology"
app.get "/MolecularPathology/*", (req, res) -> res.redirect "/molecular-pathology"
app.get "/AnatomicPathology/*", (req, res) -> res.redirect "/anatomic-pathology"
app.get "/SalesandMarketing/*", (req, res) -> res.redirect "/contact-us/sales-and-marketing"
app.get "/BillingInformation/*", (req, res) -> res.redirect "/contact-us/business-office"
app.get "/reflab/*", (req, res) -> res.redirect "/"
app.get "/portals/*", (req, res) -> res.redirect "/"
app.get "/pdfs/*", (req, res) -> res.redirect "/assets#{req.url}"

app.get "/*", (req, res) ->
  res
    .status 404
    .sendfile "out/404/index.html"

app.listen port
console.log "Listening on port #{port}"
