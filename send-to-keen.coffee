Keen = require "keen.io"
fs = require "fs"
R = require "ramda"
M = require "moment"
keenConfig = require "./keen-config.coffee"

keenClient = Keen.configure keenConfig

temperature = (location) -> (string) ->
  { location, value: parseFloat(string.slice(0, -1)), type: "temperature" }

percentage = (location) -> (s) ->
  value = if s == "ON" then 100 else 0
  { location, value, type: "percentage" }

alarm = (location) -> (s) ->
  value = if s == "ON" then 1 else 0
  { location, value, type: "alarm" }

mapping = {
  "Outdoor": temperature "outdoor"
  "Hot gas / Compr.": temperature "kompressori"
  "Heat carrier Return": temperature "paluuvesi"
  "Compressor": percentage "kompressori"
  "Alarm": alarm "heatpump"
}

report = ({location, value, type}) ->
  console.log "SENDING " + '"' + location + '"=' + value
  keenSend "sensors", { type, location, value, device: "heatpump" }

extractData = (line) ->
  #console.log "INPUT", line
  match = line.trim().substring(14).match(/^(.+) = (.+)$/)
  if (match)
    key = match[1]
    parser = mapping[key]
    if parser
      parser(match[2])

keenSend = (collection, event) ->
  console.log "Send to keen", collection, event
  keenClient.addEvent collection, event, (err, res) ->
    if err
      console.log "Keen error:  " + err
    else
      console.log "Keen sent"

files = process.argv.slice(2)

parseTime = (line) ->
  match = line.match(/^[A-Z]*:([0-9|:]+)/)
  if match?
    M(match[1], "HH:mm:ss").unix()

formatTime = (time) ->
  M.unix(time).format("HH:mm:ss")

linesLastHour = (file) ->
  last = null
  picked = []
  lines = fs.readFileSync(file, "UTF-8").split("\n").reverse()
  for line in lines
    time = parseTime(line)
    if time
      if not last?
        last = time
        console.log "last", line
      if (last - time) > 3600
        console.log "first", line
        return picked.reverse()
      picked.push(line)

files.forEach (file) ->
  lines = linesLastHour file
  valuesByLocation = {}
  for line in lines
    data = extractData(line)
    if data
      key = data.location + "-" + data.type
      values = valuesByLocation[key] || []
      values.push(data)
      valuesByLocation[key] = values
  locations = R.keys(valuesByLocation)
  locations.forEach (key) ->
    values = valuesByLocation[key]
    mean = (R.sum(R.pluck("value")(values)) / values.length).toFixed(2)
    report({location: values[0].location, value: mean, type: values[0].type})

