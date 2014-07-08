qs = require "querystring"
bodyParser = require "body-parser"
express = require "express"
lunr = require "lunr"
mailer = require "nodemailer"
request = require "request"
search = require "./search"
results = require "./results"
{mail} = require "./settings"

app = express()
index = lunr.Index.load search
smtp = mailer.createTransport "SMTP",
  service: "Gmail"
  auth:
    user: mail.user
    pass: mail.pass

app.use bodyParser.urlencoded extended: true
app.use bodyParser.json()
app.use express.static "#{__dirname}/out"

app.post "/search", (req, res) ->
  xs = index.search req.body.q
  res.send JSON.stringify xs.map (x, i) ->
    results[x.ref]

app.post "/test-list", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestList.aspx?"
  query = qs.stringify req.body
  request "#{url}#{query}&site=reflab", (err, response, body) ->
    throw err if err
    res.send JSON.stringify body

app.post "/test", (req, res) ->
  url = "http://eweb2.ccf.org/RefLabSearch/TestDetail.aspx?"
  query = qs.stringify req.body
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

router = express.Router()

router.use "/TestDirectory/*", (req, res) ->
  res.redirect "/test-directory"

router.use "/Home/*", (req, res) ->
  res.redirect "/"

router.use "/AboutUs/NewReferenceLaboratory/*", (req, res) ->
  res.redirect "/about-us"

router.use "/Publications/PathologyResearch/*", (req, res) ->
  res.redirect "/publications"

router.use "/PoliciesandProcedures/*", (req, res) ->
  res.redirect "/policies-and-procedures"

router.use "/SearchResults/*", (req, res) ->
  res.redirect "/search"

router.use "/ClientServices/ElectronicSupplyForm/*", (req, res) ->
  res.redirect "/forms/supply-order-form"

router.use "/ClientServices/*", (req, res) ->
  res.redirect "/contact-us/client-services"

router.use "/ClinicalPathology/*", (req, res) ->
  res.redirect "/laboratory-medicine"

router.use "/MolecularPathology/*", (req, res) ->
  res.redirect "/laboratory-medicine/molecular-pathology/"

router.use "/AnatomicPathology/*", (req, res) ->
  res.redirect "/pathology"

router.use "/SalesandMarketing/*", (req, res) ->
  res.redirect "/contact-us/sales-and-marketing"

router.use "/BillingInformation/*", (req, res) ->
  res.redirect "/contact-us/business-office"

app.use "/", router
app.use "/reflab", router

app.get "/*", (req, res) ->
  res
    .status 404
    .sendfile "out/404/index.html"

app.listen 3003, ->
  console.log "Listening on port 3003"
