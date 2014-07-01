chalk = require "chalk"
{exec} = require "child_process"
moment = require "moment"
watch = require "watch"

monitors =
  "src/styles": "npm run styles"
  "src/scripts": "npm run scripts"
  "src/documents": "npm run docs"
  "src/layouts": "npm run docs"
  "src/assets": "npm run build"

getTime = ->
  chalk.gray moment().format "MM/DD/YY HH:mm:ss"

run = (cmd) ->
  exec cmd, (err, stdout, stderr) ->
    throw err if err
    console.log do getTime, chalk.green "success"

addMonitor = (src, cmd) ->
  watch.createMonitor src, (monitor) ->
    monitor.on "changed", (file, curr, prev) ->
      console.log do getTime, chalk.yellow "updating #{file} ..."
      run cmd

addMonitor src, cmd for src, cmd of monitors
