defmodule TAPESTRY do

[ n1 , n2 ] = Enum.map( System.argv() , fn x -> String.to_integer(x) end )
Main.start_link( n1 , n2)

end
