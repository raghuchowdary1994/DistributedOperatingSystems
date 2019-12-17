# GOSSIPSIMULATOR

Group Members
Raghunatha Rao Ghodkari Chowdary UFID 6218-1051

Instructions to Run the Code:

1. Goto Directory gossipsimulator
2. Run the following commands
mix escript.build
./gossipsimulator noofNodes topology algorithm

For topology use:
Fullnw -> FullNetwork
line   -> Line
random2d -> Random 2D Grid
3dtorus -> 3D Torus Grid
honeycomb -> HoneyComb
honeycombrn -> HoneyComb with Random neighbor

For Algorithm use:
gossip -> Gossip Algorithm
pushsum -> Push Sum Algorithm

Output is the convergence time taken for the algorithm on topology used.

What is Working?

Convergence of Gossip Algorithm for all topologies
Full Network, Line, Random 2D, 3D Torus, Honeycomb, Honeycomb with Random Neighbor

Convergence of PushSum Algorithm for all topologies
Full Network, Line, Random 2D, 3D Torus, Honeycomb, Honeycomb with Random Neighbor

Largest Network -

Gossip Algorithm:

Full Network topology - 15000 Nodes took 993184 milli seconds to converge
Line topology         - 1500 nodes took 252139 milli seconds to converge
Random2D topology     - 4000 nodes took 48045 milli seconds to converge
3D Torus topology     - 10000 nodes took 424890 milli seconds to converge
Honeycomb topology    - 5000 nodes took 357488 milli seconds to converge
Honeycomb with RandomNeighbor topology- 5000 nodes took 144096 milli seconds to converge

Push Sum Algorithm:

Full Network topology - 5000 Nodes took 441548 milli seconds to converge
Line topology         - 1000 nodes took 419248 milli seconds to converge
Random2D topology     - 4000 nodes took 285627 milli seconds to converge
3D Torus topology     - 5000 nodes took 173795 milli seconds to converge
Honeycomb topology    - 4000 nodes took 131455 milli seconds to converge
Honeycomb with RandomNeighbor topology- 5000 nodes took 42543 milli seconds to converge
