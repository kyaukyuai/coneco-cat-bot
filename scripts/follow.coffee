cronJob = require('cron').CronJob
random  = require('hubot').Response::random
twit    = require('twit')

# for search
searchWordArray = ["ねこ","猫","kitty","ネコ","neko","cat","cats","写真"]

module.exports = (robot) ->

  keys = {
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  }
  @client = new twit(keys)

  do_tweet = ->
    searchWord = random searchWordArray
    console.log("search: #{searchWord}")
    @client.get('search/tweets', { q: searchWord, count: 3 }, (err, data, response) ->
      data.statuses.forEach (tweet) ->
        console.log("user: #{tweet.user}")
        robot.adapter.join tweet.user
    )

  cronjob = new cronJob(
    cronTime: "0 0 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      do_tweet()
  )

  cronjob.start()
