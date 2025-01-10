# Calculate the transition matrix L in ASSR
# the ara-operon network definition and compute its ASSR: n=9, m=4, q=2


using NPZ
using Revise, RobustControllability

f1(x, u, ξ) = u[1] & x[9]
f2(x, u, ξ) = (u[2] & x[9]) | u[1]
f3(x, u, ξ) = (x[2] | x[1]) & u[3]
f4(x, u, ξ) = ~u[4]
f5(x, u, ξ) = x[7]
f6(x, u, ξ) = ~x[3] & u[3] & ξ[1]
f7(x, u, ξ) = x[3] & x[4] & ~x[6]
f8(x, u, ξ) = x[3] & x[4]
f9(x, u, ξ) = x[8] | ξ[2]

fs = [f1, f2, f3, f4, f5, f6, f7, f8, f9]
# compute the ASSR, and the transition matrix is stored in L.txt
bcn = calculate_ASSR(fs, 4, 2; to_file=joinpath(@__DIR__, "model/L.txt"))
println("ASSR finished")
