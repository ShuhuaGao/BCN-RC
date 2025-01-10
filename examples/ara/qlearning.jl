## Q-learning for robust controllability of the ara-operon network

using NPZ
using Random
using Revise, RobustControllability

# make sure the ASSR is already computed
bcn = load_bcn(joinpath(@__DIR__, "model/L.txt"))
@show bcn.N bcn.M
env = Environment(bcn)
ϵ = 0.2

# load the DP result 
res = npzread(joinpath(@__DIR__, "result/res_dp.npz"))
T = TTime.(res["T"])
@show size(T)

# try different number of episodes, and record the performance as well as running time
Ps = 1:2:15
Vs = []
for P in Ps
    @show P
    max_episodes = P * bcn.N * bcn.M
    @time Q, V = run_Q_learning(env; ϵ, max_episodes, max_steps_per_episode=2*bcn.N)
    push!(Vs, V)
    # compute accuracy
    accuracy = sum(V .== T) / length(T)
    @show accuracy
    npzwrite(joinpath(@__DIR__, "result/res_ql_$P.npz"), Dict("V" => getfield.(V, :value)))
end

