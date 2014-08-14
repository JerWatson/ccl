var qs = require("querystring");
var bodyParser = require("body-parser");
var express = require("express");
var request = require("request");
var serveStatic = require("serve-static");
var mail = require("./routes/mail");
var search = require("./routes/search");

var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));
app.use(serveStatic(__dirname + "/out"));

app.post("/mail", mail);
app.post("/search", search);

app.post("/test-list", function(req, res) {
  var url = "http://eweb2.ccf.org/RefLabSearch/TestList.aspx?";
  var query = qs.stringify(req.body);
  request(url + query + "&site=reflab", function(err, response, body) {
    if (err) throw err;
    res.send(JSON.stringify(body));
  });
});

app.post("/test", function(req, res) {
  var url = "http://eweb2.ccf.org/RefLabSearch/TestDetail.aspx?";
  var query = qs.stringify(req.body);
  request(url + query + "&site=reflab", function(err, response, body) {
    if (err) throw err;
    res.send(JSON.stringify(body));
  });
});

var router = express.Router();

router.use("/TestDirectory/*", function(req, res) {
  res.redirect("/test-directory");
});

router.use("/Home/*", function(req, res) {
  res.redirect("/");
});

router.use("/AboutUs/NewReferenceLaboratory/*", function(req, res) {
  res.redirect("/about-us");
});

router.use("/Publications/PathologyResearch/*", function(req, res) {
  res.redirect("/publications");
});

router.use("/PoliciesandProcedures/*", function(req, res) {
  res.redirect("/policies-and-procedures");
});

router.use("/SearchResults/*", function(req, res) {
  res.redirect("/search");
});

router.use("/ClientServices/ElectronicSupplyForm/*", function(req, res) {
  res.redirect("/forms/supply-order-form");
});

router.use("/ClientServices/*", function(req, res) {
  res.redirect("/contact-us/client-services");
});

router.use("/ClinicalPathology/*", function(req, res) {
  res.redirect("/laboratory-medicine");
});

router.use("/MolecularPathology/*", function(req, res) {
  res.redirect("/laboratory-medicine/molecular-pathology/");
});

router.use("/AnatomicPathology/*", function(req, res) {
  res.redirect("/pathology");
});

router.use("/SalesandMarketing/*", function(req, res) {
  res.redirect("/contact-us/sales-and-marketing");
});

router.use("/BillingInformation/*", function(req, res) {
  res.redirect("/contact-us/business-office");
});

app.use("/", router);
app.use("/reflab", router);

app.use(function(req, res) {
  res.status(404);
  res.sendfile("out/404/index.html");
});

app.listen(3003, function() {
  console.log("Listening on port 3003");
});
