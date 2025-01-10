# check robust controllability via dynamic programming


# compute T¹ (matrix) and the related control set U¹ (Dict)
function compute_base_case(bcn::BCN)
    (; M, N, Q) = bcn
     sizeof(bcn)
    T¹ = fill(InfTime, N, N)
    # typically, only a small fraction of (s, e) is robustly reachable
    # thus, we only store control for reachable pairs 
    # multi-threading, each thread has its own u vector to fill
    us_list = [collect(UInt8, 1:M) for _ in 1:Threads.nthreads()]
    U_list = [Dict{Tuple{Int64, Int64}, Vector{TC}}() for _ in 1:Threads.nthreads()]
    
    Threads.@threads for e in 1:N
        for s in 1:N
            us = us_list[Threads.threadid()]
            empty!(us)
            # whether s robustly reaches e by control u
            for u in 1:M
                if all(step(bcn, s, u, ξ) == e for ξ in 1:Q)
                    push!(us, u)
                end
            end
            if !isempty(us)
                T¹[s, e] = 1
                U = U_list[Threads.threadid()]
                U[s, e] = copy(us)
            end
        end
    end
    # combine the dispersed dictionaries into a big one
    U¹ = Dict{Tuple{Int64, Int64}, Vector{TC}}()
    merge!(U¹, U_list...)
    return (T¹, U¹)
end


# one-step reachable set 
function compute_R1!(R::Vector, bcn::BCN, i, j)
    empty!(R)
    for ξ = 1:bcn.Q
        push!(R, step(bcn, i, j, ξ))
    end 
    return R
end

compute_R1(bcn::BCN, i, j) = compute_R1!(Vector{Int64}(), bcn, i, j)



"""
    check_robust_controllability(bcn::BCN; verbose::Bool=false)

Compute the optimal time matrix `T` and optimal control dict `U` for the given Boolean network.
If `verbose` is set, then print the intermediate results.
Each entry of `U` is a vector of integers representing controls.
If a pair (s, e) does not stay in U, then it means s cannot reach e robustly.
"""
# return optimal time matrix T and control matrix U as matrices
# if `verbose` is set, then print the intermediate results
function check_robust_controllability(bcn::BCN; verbose::Bool=false)
    @show Threads.nthreads()
    (; M, N, Q) = bcn
    println("Computing the base case...")
    (T¹, U¹) = compute_base_case(bcn)
    println("   Base case finished.")
    @assert eltype(T¹) == TT 
    k = 1
    T = copy(T¹)
    T′ = copy(T¹)
    if verbose
        println("T1")
        display(T¹)
    end
    # Julia has no do-while flow; we use while-break instead.
    R_list = [collect(Int, 1:N) for _ in 1:Threads.nthreads()]
    println("RDP in process...")
    while true
        k += 1 
        Threads.@threads for e in 1:N
            for s in 1:N
                R = R_list[Threads.threadid()]
                if T¹[s, e] != TT(1)  # i.e., ϕ(s, e) != 1
                    T′[s, e] = minimum(maximum_time(T[r, e] for r in compute_R1!(R, bcn, s, j)) + 1 for j in 1:M)
                end
            end
        end
        println("   Iteration $(k-1) finished.")
        if verbose
            println("T$k:")
            display(T′)
        end
        if T == T′
            break
        else
            T, T′ = T′, T
        end
    end
    println("RDP finished. Took $(k - 1) iterations in total")

    res_list = [Vector{TT}(undef, M) for _ in 1:Threads.nthreads()]
    us_list = [collect(UInt8, 1:M) for _ in 1:Threads.nthreads()]
    U_list = [Dict{Tuple{Int64, Int64}, Vector{TC}}() for _ in 1:Threads.nthreads()]
    Threads.@threads for e in 1:N
        for s in 1:N
            if TT(1) < T[s, e] < InfTime
                # compute the RHS for each u and collect them
                R = R_list[Threads.threadid()]
                res = res_list[Threads.threadid()]
                for j = 1:M
                    res[j] = 1 + maximum_time(T[r, e] for r in compute_R1!(R, bcn, s, j))
                end
                # find all control associated with min value in res
                min_value = minimum(res)
                us = us_list[Threads.threadid()]
                empty!(us)
                for u in 1:M
                    if res[u] == min_value
                        push!(us, u)
                    end
                end
                U_list[Threads.threadid()][(s, e)] = copy(us)
            end
        end
    end
    merge!(U¹, U_list...)
    return T, U¹
end


