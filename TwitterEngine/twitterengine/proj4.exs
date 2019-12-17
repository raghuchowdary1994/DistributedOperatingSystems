defmodule Proj4 do

[ n1 , n2 ] = Enum.map( System.argv() , fn x -> String.to_integer(x) end )
Main.startProgram(n1, n2)

end
