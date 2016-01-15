cronJob      = require('cron').CronJob
random       = require('hubot').Response::random
request_json = require('request-json')
request      = require('request')
fs           = require('fs')
twit         = require('twit')
async        = require('async')

module.exports = (robot) ->

  keysForImage = {
    consumer_key:        process.env.HUBOT_TWITTER_KEY
    consumer_secret:     process.env.HUBOT_TWITTER_SECRET
    access_token:        process.env.HUBOT_TWITTER_TOKEN
    access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET
  }
  @clientForImage = new twit(keysForImage)

  do_tweet = ->
    async.series({
      search: (callback) ->
        conecoUrl  = 'http://coneco.cat2.pics/api/v1/cats/like'
        randomPage = random [0..50]
        conecoUrl += '?page=' + randomPage
        console.log("search: #{conecoUrl}")
        coneco_client = request_json.createClient(conecoUrl)
        coneco_client.get('', (err, res, body) ->
          value       = random [0..body.length-1]
          console.log("value: #{value}")
          image_url   = body[value].image_url
          text        = body[value].text
          tags        = body[value].tags
          link        = body[value].link
          request.get(image_url)
            .on('response', (res) ->
            ).pipe(fs.createWriteStream('./images/coneco_saved.jpg'))
          tweet = """
            #{text}...
            #{link}
          """
          callback(null, tweet)
        )
      post: (callback) ->
        setTimeout(
          () ->
            callback(null, 'post')
          , 10000
        )
    }, (err, result) ->
      b64img = fs.readFileSync('./images/coneco_saved.jpg', { encoding: 'base64' })
      @clientForImage.post('media/upload', { media_data: b64img }, (err, data, res) ->
        mediaIdStr = data.media_id_string
        params = { status: result.search, media_ids: [mediaIdStr] }
        @clientForImage.post('statuses/update', params, (e, d, r) ->
        )
      )
    )

  cronjob = new cronJob(
    cronTime: '0 5,25,45 * * * *'
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      do_tweet()
  )

  cronjob.start()
