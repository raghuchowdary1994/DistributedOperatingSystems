# TAPESTRY

Group Members
Raghunatha Rao Ghodkari Chowdary   UFID 6218-1051

Instructions to Run the Code:

1. Goto Directory tapestry
2. Run the following commands
mix escript.build
./tapestry noofNodes noofRequests

What is working :

Initially routing table is built for 80% of the nodes
For the remaining 20% of the nodes join operation is performed.
Routing is performed for each node which invokes requests by selecting random destination. The maximum hop is printed on the console.
The last maximum hop value is the final no of max hops calculated by the program.

Largest Network :
Largest Network dealt with the program is 10,000 Nodes 10 requests, Its taking around 15 min to run. For larger networks, the program will take a lot of time.
