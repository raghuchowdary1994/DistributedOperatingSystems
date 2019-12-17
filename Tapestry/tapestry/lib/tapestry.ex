defmodule TAPESTRY do


def main(argv) do
[ n1 , n2 ] = argv
Main.start_link( String.to_integer(n1), String.to_integer(n2) )

end

end
