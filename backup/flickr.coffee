cronJob      = require('cron').CronJob
random       = require('hubot').Response::random
request_json = require('request-json')
request      = require('request')
fs           = require('fs')
twit         = require('twit')
async        = require('async')

# for flickr
textArray = ['ねこ','猫','kitty','ネコ','neko','cat']
sortArray = ['date-posted-desc','date-taken-desc','interestingness-desc','interestingness-asc']

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
        flickrUrl     = 'https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=4480c9059211841b6a5101941b2724df&extras=owner_name%2Curl_s%2Ctags&format=json&nojsoncallback=1'
        text           = random textArray
        flickrUrl    += '&text=' + encodeURIComponent(text)
        sort           = random sortArray
        flickrUrl    += '&sort=' + encodeURIComponent(sort)
        flickr_client = request_json.createClient(flickrUrl)
        console.log("search: #{text}")
        console.log("search: #{sort}")
        console.log("search: #{flickrUrl}")
        flickr_client.get('', (err, res, body) ->
          value = random [0..body.photos.perpage-1]
          console.log("value: #{value}")
          request.get(body.photos.photo[value].url_s)
            .on('response', (res) ->
            ).pipe(fs.createWriteStream('./images/flickr_saved.jpg'))
          tweet = """
            #{body.photos.photo[value].title}
            by Flickr@#{body.photos.photo[value].ownername}
            #{body.photos.photo[value].tags.substring(0, 30)}...
            \#Flickr \#cat \#猫 \#ネコ \#ねこ
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
      b64img = fs.readFileSync('./images/flickr_saved.jpg', { encoding: 'base64' })
      @clientForImage.post('media/upload', { media_data: b64img }, (err, data, res) ->
        mediaIdStr = data.media_id_string
        params = { status: result.search, media_ids: [mediaIdStr] }
        @clientForImage.post('statuses/update', params, (e, d, r) ->
        )
      )
    )

  cronjob = new cronJob(
    cronTime: "0 20,40 * * * *"
    start: true
    timeZone: "Asia/Tokyo"
    onTick: ->
      do_tweet()
  )

  cronjob.start()
