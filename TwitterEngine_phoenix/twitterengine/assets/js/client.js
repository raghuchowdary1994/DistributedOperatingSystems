var tweet = 0

let client = {

  
  init( socket ){
    let channel = socket.channel( 'twitterengine:lobby', {})
    channel.join()
    this.listenForChats(channel)
  },

  listenForChats(channel){
      document.getElementById("login").onclick = function(e){
        e.preventDefault()
        let login_name = document.getElementById('fname').value
        channel.push('login',{name:login_name})
      }

      document.getElementById("register").onclick = function(e){
        e.preventDefault()
        let register_name = document.getElementById("fname").value
        channel.push('register', {name:register_name})
      }

      document.getElementById("follow").onclick = function(e){
        e.preventDefault()
        let follower_name = document.getElementById("followuser").value
        let logged_name = document.getElementById('fname').value
        channel.push('follow', {f_name:follower_name, l_name:logged_name})
      }


      document.getElementById("sendTweet").onclick = function(e){
        e.preventDefault()
        let msg = document.getElementById("tweet").value
        let username = document.getElementById("fname").value
        channel.push( 'send_tweet' , {u_name:username, tweet:msg})
      }

      document.getElementById("send_retweet").onclick = function(e){
        e.preventDefault()
        let msg = document.getElementById("retweetid").value
        let username = document.getElementById("fname").value
        channel.push( 'retweet', {u_name:username, tweet: msg } )
      }

      document.getElementById("queryMentions").onclick = function(e){
        e.preventDefault()
        let mention = document.getElementById("mention").value
        let username = document.getElementById("fname").value
        channel.push( 'query_mention' , { m_user:mention , u_name:username } )
      }

      document.getElementById("queryHashtags").onclick = function(e){
        e.preventDefault()
        let hashtag = document.getElementById("hashtag").value
        let username = document.getElementById("fname").value
        channel.push( 'query_hashtag' , { h_user:hashtag , u_name:username } )
      }

      channel.on( 'onlineFeed', payload => {
        let chatBox = document.querySelector('#onlinefeed')
        let output = document.createElement('p')
        output.insertAdjacentHTML('beforeend', payload.body)
        chatBox.appendChild(output)

      } )

      

      channel.on( 'register',payload => {
        let chatBox = document.querySelector('#onlinefeed')
        let output = document.createElement('p')

        if( payload.response == 1 ){
          output.insertAdjacentHTML('beforeend' , 'register action is completed' )
        }else{
          output.insertAdjacentHTML('beforeend', 'register action failed try with different user')
          document.getElementById("fname").value = ''
        }
        chatBox.appendChild(output)
      } )

      channel.on( 'login', payload => {
        let chatBox = document.querySelector('#onlinefeed')
        let output = document.createElement('p')

        if( payload.response == 0 ){
            output.insertAdjacentHTML('beforeend', 'user is not found ')
            document.getElementById('login').value = ''
        }else{
            output.insertAdjacentHTML('beforeend', 'User logged in')
            let name = document.querySelector('#username')
            let block = document.createElement('h3')
            let fname = document.getElementById('fname').value
            block.insertAdjacentHTML('beforeend', 'Welcome ' + fname)
            name.appendChild(block)
            afterLogin.style.display = "block"
        }
        chatBox.appendChild(output)

      } )






      channel.on( 'follow' , payload => {
        let chatBox = document.querySelector('#onlinefeed')
        let output = document.createElement('p')
        
        if( payload.response == 0 ){
          output.insertAdjacentHTML('beforeend' , 'addition follower unsuccesfull')
        }else{
          output.insertAdjacentHTML('beforeend', 'follower added successfully')
        }

        document.getElementById('followuser').value = ''
        chatBox.appendChild(output)

      } )


      



  }

}

export default client