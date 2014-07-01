express = require "express"
mailer = require "nodemailer"
request = require "request"
qs = require "querystring"

app = do express
port = 3003
smtp = mailer.createTransport "SMTP",
  service: "Gmail"
  auth:
    user: "clevelandcliniclabs@gmail.com"
    pass: "***REMOVED***"

app.configure ->
  app.use do express.urlencoded
  app.use do express.json
  app.use express.static "#{__dirname}/out"
  app.use app.router

search = (url, res) ->
  request url, (err, response, body) ->
    throw err if err
    res.send JSON.stringify body

app.get "/test-list", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestList.aspx?"
  query = qs.stringify req.query
  search "#{url}#{query}&site=reflab", res

app.get "/test-detail", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestDetail.aspx?"
  query = qs.stringify req.query
  search "#{url}#{query}&site=reflab", res

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
