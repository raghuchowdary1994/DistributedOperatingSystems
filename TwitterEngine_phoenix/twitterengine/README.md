# Twitterengine Phoenix Integration

Link to Demo Video: https://youtu.be/be3sGACA8j4

How to run
1. Unzip the folder GhodkariChowdary.zip
2. From terminal go to folder twitterengine
3. Run command “mix phx.server” this starts the server
4. Go to URL from a web browser http://localhost:4000/

What is working?
Basic UI is created in HTML/Javascript, it’s an interface for our channels in phoenix which is connected to server. 

The UI is very basic to show the functionalities of the Twitter Project 4.1
UI has following functionalities:
1.	Register User: A user is registered and an entry is added to ets table present on the server side
2.	Login User: we create a socket for the single user, its channel id is stored in ets table on server side to maintain its session
3.	Follow: Username is written in this input whom to follow and you are added to the users following list and that user is added to your following list maintain at server side in ets table
4.	Tweet: A user can post a tweet from the text field and post it to his corresponding followers
5.	Retweet: A user can input the tweeted from his received tweets which can be retweeted again to send to his followers 
6.	Query Hashtags: It gives all the tweets which has corresponding hashtag
7.	Query Mentions: It gives all the tweets which has corresponding user mention

For each user there is online feed box created at top that shows all the ongoing actions trigged by each user.