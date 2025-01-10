# Calculate the transition matrix L in ASSR
# the cortical network definition and compute its ASSR: n=5, m=2, q=2


using NPZ
using Revise, RobustControllability

f1(x, u, ξ) = ~ ( (x[4]) | (x[3]) ) | ~( (x[4]) | (x[3]) ) | u[1] | ξ[1]
f2(x, u, ξ) = ( ( (x[1]) & ~ (x[3]) ) & ~ (x[5]) ) & ~ (x[4]) & u[2]
f3(x, u, ξ) = ( (x[3]) & ( (x[4]) | ξ[2]) ) & ~ (x[2])
f4(x, u, ξ) = ( (x[3]) & ~ (x[2]) ) | u[1]
f5(x, u, ξ) = ( ( (x[4]) & ~ (x[1]) ) & ~ (x[2]) ) & ξ[1]

fs = [f1, f2, f3, f4, f5]

# compute the ASSR, and the transition matrix is stored in L.txt
bcn = calculate_ASSR(fs, 2, 2; to_file=joinpath(@__DIR__, "model/L.txt"))
println("ASSR finished")
