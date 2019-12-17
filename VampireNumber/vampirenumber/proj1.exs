defmodule Proj1 do

[ n1 , n2 ] = Enum.map( System.argv() , fn x -> String.to_integer(x) end )
Boss.start_link(n1,n2)

end
