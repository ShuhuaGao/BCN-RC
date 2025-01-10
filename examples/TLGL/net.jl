# Calculate the transition matrix L in ASSR
# the TLGL network definition and compute its ASSR: n=16, m=3, q=4


using NPZ
using Revise, RobustControllability

f1(x, u, ξ) = x[2] & ~x[16] & u[1]
f2(x, u, ξ) = ~(x[5] | x[3] | x[16] | ξ[1])
f3(x, u, ξ) = (x[2] | x[3] | u[2]) & ~x[16]
f4(x, u, ξ) = x[15] & ~x[16]
f5(x, u, ξ) = x[4] & ~x[16] | (u[3] & ξ[2])
f6(x, u, ξ) = ~(x[7] | x[16])
f7(x, u, ξ) = x[15] & ~x[16]
f8(x, u, ξ) = x[6] & ~(x[15] | x[16]) & ~u[4]
f9(x, u, ξ) = (x[8] | (x[6] & ~x[11])) & ~x[16]
f10(x, u, ξ) = ((x[12] & ~x[13]) | x[9]) & ~x[16]
f11(x, u, ξ) = ~(x[9] | x[16])
f12(x, u, ξ) = ~(x[14] | x[16] | u[2])
f13(x, u, ξ) = ~(x[12] | x[16]) | ξ[3]
f14(x, u, ξ) = ~(x[9] | x[16]) & u[1]
f15(x, u, ξ) = ~(x[8] | x[16])
f16(x, u, ξ) = x[10] | x[16] | (u[2] & u[3])

fs = [f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16]
# compute the ASSR, and the transition matrix is stored in L.txt
bcn = calculate_ASSR(fs, 4, 3; to_file=joinpath(@__DIR__, "model/L.txt"))
println("ASSR finished")

