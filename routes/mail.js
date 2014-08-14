var mail = require("nodemailer");
var config = require("../config");

var smtp = mail.createTransport({
  service: "Gmail",
  auth: config.mail
});

module.exports = function(req, res) {
  var content = [
    "<i>Please do NOT reply to this automated message.</i>",
    "<br><br>"
  ].join("");
  for (var key in req.body) {
    var val = req.body[key];
    if (!(val === "" || key === "Form" || key === "To")) {
      content += "<b>" + key + "</b>: " + val + "<br>";
    }
  }
  var options = {
    from: "Cleveland Clinic Laboratories <clevelandcliniclabs@gmail.com>",
    bcc: req.body.To,
    subject: req.body.Form + " submitted",
    html: content
  };
  smtp.sendMail(options, function(err, info) {
    if (err) throw err;
    res.send(JSON.stringify(info.response));
  });
};
