mail = require "nodemailer"
settings = require "../settings"

smtp = mail.createTransport
  service: "Gmail"
  auth: settings.mail

module.exports = (req, res) ->
  content = "<i>Please do NOT reply to this automated message.</i><br><br>"
  for key, val of req.body
    unless val is "" or key is "Form" or key is "To"
      content += "<b>#{key}</b>: #{val}<br>"
  options =
    from: "Cleveland Clinic Laboratories <clevelandcliniclabs@gmail.com>"
    bcc: req.body.To
    subject: "#{req.body.Form} submitted"
    html: content
  smtp.sendMail options, (err, info) ->
    throw err if err
    res.send JSON.stringify info.response
