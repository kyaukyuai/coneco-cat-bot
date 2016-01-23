cronJob      = require('cron').CronJob
random       = require('hubot').Response::random
request_json = require('request-json')
request      = require('request')
fs           = require('fs')
twit         = require('twit')
async        = require('async')

# for 500px
termsArray = ['ねこ','猫','kitty','ネコ','neko','cat']
sortArray  = ['favorites_count','_sort','rating','highest_rating','times_viewed']

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
        _500pxUrl    = 'https://api.500px.com/v1/photos/search?consumer_key=wso0y9t1n3iVnqo8DYQzbfrgaqACNAzaz09bcRwe&image_size=3'
        term         = random termsArray
        _500pxUrl   += '&term=' + encodeURIComponent(term)
        sort         = random sortArray
        _500pxUrl   += '&sort=' + encodeURIComponent(sort)
        _500px_client = request_json.createClient(_500pxUrl)
        value = random [0..19]
        console.log("search: #{term}")
        console.log("search: #{sort}")
        console.log("search: #{_500pxUrl}")
        _500px_client.get('', (err, res, body) ->
          request.get(body.photos[value].image_url)
            .on('response', (res) ->
            ).pipe(fs.createWriteStream('./images/500px_saved.jpg'))
          tweet = """
            #{body.photos[value].name}
            by 500px@#{body.photos[value].user.username}
            https://500px.com#{body.photos[value].url}
            \#500px \#cat \#猫 \#ネコ \#ねこ
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
      b64img = fs.readFileSync('./images/500px_saved.jpg', { encoding: 'base64' })
      @clientForImage.post('media/upload', { media_data: b64img }, (err, data, res) ->
        mediaIdStr = data.media_id_string
        params = { status: result.search, media_ids: [mediaIdStr] }
        @clientForImage.post('statuses/update', params, (e, d, r) ->
        )
      )
    )

  cronjob = new cronJob(
    cronTime: "0 20 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      do_tweet()
  )

  cronjob.start()
