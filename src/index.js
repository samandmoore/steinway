const Mta = require('mta-gtfs')
const moment = require('moment-timezone')

const api_token = process.env['MTA_TOKEN']
const steinway_stop_id = 'G19'
const nqrw_feed_id = 16
const bdfm_feed_id = 21
const ace_feed_id = 26

let mta = new Mta({
  key: api_token,
  feed_id: nqrw_feed_id
})

function toTime(value) {
  return moment.tz(value*1000, "America/New_York")
}

function printTrain(train) {
  arrivalTime = toTime(train.arrivalTime)
  console.log(`${train.routeId} arriving ${arrivalTime.fromNow()}`)
}

function printTrains(trains) {
  trains.slice(0, 3).forEach((train) => {
    printTrain(train)
  })
}

function printDirection(direction) {
  mta.schedule(steinway_stop_id, nqrw_feed_id).then((result) => {
    printTrains(result.schedule[steinway_stop_id][direction])
  })

  mta.schedule(steinway_stop_id, bdfm_feed_id).then((result) => {
    printTrains(result.schedule[steinway_stop_id][direction])
  })

  mta.schedule(steinway_stop_id, ace_feed_id).then((result) => {
    printTrains(result.schedule[steinway_stop_id][direction])
  })
}

printDirection('S')
