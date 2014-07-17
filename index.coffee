qs = require "querystring"
bodyParser = require "body-parser"
express = require "express"
request = require "request"
serveStatic = require "serve-static"
mail = require "./routes/mail"
search = require "./routes/search"

app = express()

app.use bodyParser.json()
app.use bodyParser.urlencoded extended: true
app.use serveStatic "#{__dirname}/out"

app.post "/mail", mail
app.post "/search", search

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

# Router for redirecting pages from the old site to their new URLs
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

app.use (req, res) ->
  res.status 404
  res.sendfile "out/404/index.html"

app.listen 3003, ->
  console.log "Listening on port 3003"
