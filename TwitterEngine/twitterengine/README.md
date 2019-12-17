# TWITTERENGINE

Group Members
Raghunatha Rao Ghodkari Chowdary   UFID 6218-1051
Chirag Maroke                      UFID 1595-7951

Instructions to Run the Code:
1.	Unzip the folder GhodkariChowdaryMaroke.zip
2.	From terminal go to folder twitterengine
3.	Run command “mix run proj4.exs numofusers noofRequests”.
Ex.  mix run proj4.exs 100 5, where the project takes 100 users and each user sends 5 tweets

What is working :
Twitter Simulator is working for sending the tweets, querying the tweets based on hashtags and user mentions and we can also facilitate the user online and offline. The output console is the live feed happening by interaction of the users and the TwitterEngine.

Functionalities that  implemented
1.	Register account and delete account for user
2.	Send tweet, where tweets can have hashtags and mentions
3.	Users can subscribe to other user’s tweets, (followers)
4.	Retweet, a user can re tweet an interesting tweet received
5.	Querying of tweets with hashtags and mentions
6.	Live feed of tweets available to user without querying if he is online


Mention all the test cases that you created
For each functionality there are 2 test cases available
o	Test cases for user registration where the user registered is stored in the user ets table 
o	Test cases to check if the followers and following are build for the user
o	Test cases to send the tweet where a user sends the tweet and the followers of that user receives the tweets  
o	Test cases where a user queries the tweets based on the hashtags and mentions
o	Test cases where we set user online and offline
o	Test cases for user deletion where the user is delete in the table, from user active list
o	Test cases for retweet the user from the tweets received
o	Test cases to check the live feed where the user comes online and gets the tweets without the querying
