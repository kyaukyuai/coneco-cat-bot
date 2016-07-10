cronJob      = require('cron').CronJob
random       = require('hubot').Response::random
request_json = require('request-json')
request      = require('request')
fs           = require('fs')
twit         = require('twit')
async        = require('async')

# for instagram
tagsArray = ['ねこ','猫','kitty','にゃんこ','instacat','ネコ','neko','にゃんこ','cat','lovecats','cats','ilovecat']

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
        instagramUrl     = 'https://api.instagram.com/v1/tags/'
        tag              = random tagsArray
        instagramUrl    += encodeURIComponent(tag) + '/media/recent?client_id=9ad0d13ba1bc4af68fd60217ad853471&max_tag_id=980964481902499453'
        instagram_client = request_json.createClient(instagramUrl)
        value = random [0..19]
        console.log("search: #{tag}")
        console.log("search: #{instagramUrl}")
        instagram_client.get('', (err, res, body) ->
          request.get(body.data[value].images.low_resolution.url)
            .on('response', (res) ->
            ).pipe(fs.createWriteStream('./instagram_saved.jpg'))
          tweet = """
            #{body.data[value].link}
            by Instagram@#{body.data[value].user.full_name}
            #{body.data[value].caption.text.substring(0, 30)}...
            \#Instagram \#cat
          """
          callback(null, tweet)
        )
      post: (callback) ->
        setTimeout(
          () ->
            callback(null, 'post')
          , 5000
        )
    }, (err, result) ->
      b64img = fs.readFileSync('./instagram_saved.jpg', { encoding: 'base64' })
      @clientForImage.post('media/upload', { media_data: b64img }, (err, data, res) ->
        mediaIdStr = data.media_id_string
        params = { status: result.search, media_ids: [mediaIdStr] }
        @clientForImage.post('statuses/update', params, (e, d, r) ->
        )
      )
    )

  cronjob = new cronJob(
    cronTime: "0 0 5,13,21 * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      do_tweet()
  )

  cronjob.start()
