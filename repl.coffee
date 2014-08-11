chalk = require "chalk"
es = require "elasticsearch"
readline = require "readline"

client = new es.Client
  host: "localhost:9200"

rl = readline.createInterface
  input: process.stdin
  output: process.stdout

rl.setPrompt "search> "
rl.prompt()

rl
  .on "line", (line) ->
    client.search
      q: line.trim()
    , (err, res) ->
      throw err if err
      res.hits.hits.forEach (hit) ->
        console.log chalk.green(hit._source.url), hit._score
      rl.prompt()
  .on "close", ->
    console.log "exiting"
    process.exit 0
