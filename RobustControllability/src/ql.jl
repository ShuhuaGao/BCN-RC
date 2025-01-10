########### Q learning ################

struct Environment
    bcn::BCN
end

"""
    step(env::Environment, x::Integer, u::Integer)

Return the next state of the BCN given the current state `x` and control `u` subject to random disturbance.
"""
function step(env::Environment, x::Integer, u::Integer)
    Q =  env.bcn.Q
    ξ = rand(1:Q)  # random disturbance
    return step(env.bcn, x, u, ξ)
end


"""
    run_Q_learning(env::Environment, e::Integer; ϵ::Float64=0.2, 
        max_episodes::Integer=100*env.bcn.N*env.bcn.M, max_steps_per_episode::Integer=2*env.bcn.N)

Run Q-learning for one target state `e` and all initial states of the BCN.
A matrix `Q` is returned, where `Q[s, a]` is the action value for state `s` and control `a`.
A vector `V` is returned, where `V[s]` is the value for state `s`.
Conceptually, `V[s]` denotes the *shortest control time* from state `s` to state `e`, which can be `Inf`.

Note: 
- if there is any Q[s, a] = 0, then this state-action pair is never visited.
- the parameter `max_steps_per_episode` should be >= `N`, where `N` is the number of states.
"""
function run_Q_learning(env::Environment, e::Integer; ϵ::Float64=0.2, 
        max_episodes::Integer=100*env.bcn.M*env.bcn.N, max_steps_per_episode::Integer=2*env.bcn.N)
    bcn = env.bcn
    M, N = bcn.M, bcn.N
    @assert max_steps_per_episode >= N "max_steps_per_episode must be >= N"

    Q = zeros(N, M)
    probabilities = fill(1.0/N, N)

    for ep in 1:max_episodes
        # choose initial state for this episode
        # if there is any (s, a) = 0, then select s with higher probability
        for s in 1:N
            if any(iszero, @view Q[s, :])
                probabilities[s] = 10.0 / N
            else
                probabilities[s] = 1.0 / N 
            end
        end
        s = sample(1:N, ProbabilityWeights(probabilities)) 

        for _ in 1:max_steps_per_episode
            # choose action using ϵ-greedy
            if rand() < ϵ
                a = rand(1:M)
            else
                a = argmin(@view Q[s, :])
            end
            # execute action, and observe the next state 
            s′ = step(env, s, a)
            # update Q
            ## terminal state
            if s′ == e
                Q[s, a] = max(Q[s, a], 1)
                break
            end
            ## non-terminal state
            Q[s, a] = max(Q[s, a], 1 + minimum(@view Q[s′, :]))
            if Q[s, a] >= N
                Q[s, a] = Inf
            end
            # transit to next state
            s = s′
        end
    end

    num_zeros = count(iszero, Q)
    if num_zeros > 0
        @warn "There are $num_zeros zeros in Q for target state $e, which means $e state-action pairs are never visited." *
         "The result is probably wrong. Try to increase `max_episodes` or `max_steps_per_episode`."
    end
    V = minimum(Q; dims=2)
    # turn V and Q into `TTime` types to save memory and to ease comparison with our DP method
    Q = convert.(TTime, Q)
    V = convert.(TTime, V)
    return Q, V
end


"""
    run_Q_learning(env::Environment; ϵ::Float64=0.2, max_episodes::Integer=100*env.bcn.N, 
        max_steps_per_episode::Integer=2*env.bcn.N, verbose::Bool=false) 

Run Q-learning for all target states and all initial states of the BCN.
A 3D array `Q` is returned, where `Q[s, a, e]` is the action value for state `s->e` and control `a`.
A matrix `V` is returned, where `V[s, e]` is the value for state `s->e`.
Conceptually, `V[s, e]` denotes the *shortest control time* from state `s` to state `e`, which can be `Inf`.

Note: 
- if there is any Q[s, a, e] = 0, then this state-action pair is never visited.
- the parameter `max_steps_per_episode` should be >= `N`, where `N` is the number of states.
"""
function run_Q_learning(env::Environment; ϵ::Float64=0.2, max_episodes::Integer=100*env.bcn.N, 
        max_steps_per_episode::Integer=2*env.bcn.N, verbose::Bool=false)
    bcn = env.bcn
    M, N = bcn.M, bcn.N

    Q = zeros(TTime, N, M, N)
    V = zeros(TTime, N, N)

    for e in 1:N
        if verbose && e % 10 == 0
            println("Progress: $e / $N")
        end
        Q[:, :, e], V[:, e] = run_Q_learning(env, e; ϵ, max_episodes, max_steps_per_episode)
    end

    return Q, V
end