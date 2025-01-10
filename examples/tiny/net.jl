# Calculate the transition matrix L in ASSR
# the tiny network definition and compute its ASSR: n=2, m=1, q=1


using NPZ
using Revise, RobustControllability

f1(x, u, ξ) = (x[1] == x[2]) | u[1]
f2(x, u, ξ) = (~x[1]) & ξ[1]

fs = [f1, f2]

# compute the ASSR, and the transition matrix is stored in L.txt
bcn = calculate_ASSR(fs, 1, 1; to_file=joinpath(@__DIR__, "model/L.txt"))
println("ASSR finished")
