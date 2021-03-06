// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()
let channel = socket.channel("twitterengine:lobby", {})


// var cached_tweets = []
// // Now that you are connected, you can join channels with a topic:

// var username;
// let user_name = document.getElementById("fname")
// let register = document.querySelector("#register")//document.getElementById("register")
// let login = document.querySelector("#login")
// let client_tweet = document.getElementById("tweet")
// let send_tweet = document.querySelector("#sendTweet")
// let client_subscribe = document.querySelector("#subscribe")
// let subscribe_to = document.getElementById("subscribeTo")
// let client_hashtag = document.getElementById("hashtag")
// let query_hashtag = document.querySelector("#queryHashtags")
// let client_mention = document.getElementById("mention")
// let query_mention = document.querySelector("#queryMentions")
// let get_tweets = document.querySelector("#getTweets")
// let tweets_list = document.getElementById("tweetsList")
// let hashtags_list = document.getElementById("hashtagsList")
// let mentions_list = document.getElementById("mentionsList")
// ///ADDED
// let retweet_div = document.getElementById("retweetDiv")
// let client_retweet_number = document.getElementById("retweetNo")
// let retweet = document.querySelector("#retweet")
// let after_login_div = document.getElementById("afterLogin")
// let userdata = document.getElementById("hideuserdata")

// register.addEventListener("click", function(){
//   username = user_name.value
//   channel.push("register", {username: user_name.value})
// })
// login.addEventListener("click", function(){
//   username = user_name.value
//   channel.push("login", {username: user_name.value})
// })
// send_tweet.addEventListener("click", function(){
//   username = user_name.value
//   console.log(client_tweet.value)
//   channel.push("send_tweet", {username: username, tweet: client_tweet.value})
// })
// client_subscribe.addEventListener("click", (e) =>{
//   channel.push("follow", {username: username, following_user: subscribe_to.value})
// })
// query_hashtag.addEventListener("click", (e) =>
// {
//   channel.push("hashtag", {username: username, hashtag: client_hashtag.value})
// })
// query_mention.addEventListener("click", function(){
//   channel.push("mentions", {queried: client_mention.value, username: username})
// })
// get_tweets.addEventListener("click",  function(){
//   channel.push("get_tweets", {username: username})
// })
// ///ADDED
// retweet.addEventListener("click", function(){
//   var tweet = cached_tweets[parseInt(client_retweet_number.value) - 1];
//   channel.push("retweet", {tweet: tweet, username: username})
// })
// let renderMessage = (message) => {
//   tweets_list.style.display = "block";
//   var i;
//   //ADDED
//   if (message.tweets[0] != "No tweets found!")
//     cached_tweets = cached_tweets.concat(message.tweets)
//   console.log("tweets = " + cached_tweets)
//   //tweets_list.setAttribute('hidden', 'false');
//   for (i = 0; i < message.tweets.length; i++)
//   {
//     var li = document.createElement("li");
//     li.textContent = message.tweets[i];
//     tweets_list.appendChild(li);
//   }
//   /////ADDED
//   retweet_div.style.display = "block"
//   // tweets_list.appendChild(messageElement)
//   tweets_list.scrollTop = tweets_list.scrollHeight;
// }

// let updateQueryHashTag = (hashtags) => {
//    /*let messageElement = document.createElement("li")
//    messageElement.innerHTML = `
//     <b>${message.tweets}</b>
//     `
//   hashtags_list.appendChild(messageElement)*/
//   hashtags_list.style.display = "block";
//   var i;
//   for (i = 0; i < hashtags.tweets.length; i++) {
//     var li = document.createElement("li");
//     li.textContent = hashtags.tweets[i];
//     hashtags_list.appendChild(li);
//   }
//   hashtags_list.scrollTop = hashtags_list.scrollHeight;

// }
// let updateQueryMention = (mentions) => {
//   mentions_list.style.display = "block";
//   var i;
//   for (i = 0; i < mentions.tweets.length; i++) {
//     var li = document.createElement("li");
//     li.textContent = mentions.tweets[i];
//     mentions_list.appendChild(li);
//   }
//   mentions_list.scrollTop = mentions_list.scrollHeight;

// }

// let loadrest = (val) => {
//   if (val.ret == true)
//   {
//     after_login_div.style.display = "block"
//     userdata.style.display = "none"
//   }
//   else
//   {
//     user_name.value = ""
//   }
// }
// channel.on("loginsuccessful", result => loadrest(result))
// channel.on("return_tweets", result => renderMessage(result))

// channel.on("hashtag", result =>  updateQueryHashTag(result))

// channel.on("mentions", result => updateQueryMention(result))


channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
