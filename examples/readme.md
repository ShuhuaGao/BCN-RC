The files in each example directory are organized as follows
- `net.jl`: algorithms to compute the ASSR model. If the model has not been computed yet, please first execute this file to generate `model/L.txt`, since `dp.jl` and `qlearning.jl` depends on `model/L.txt`.
- `model/L.txt`: store the model of the BCN including `M, N, Q` and the vector form of `L`
- `dp.jl`: dynamic programming solution
- `qlearning.jl`: Q-learning solution
- `result/`: this directory contains intermediate and final results of different methods
  - the NPZ files contain DP and Q learning results for further use, e.g., in Python
  - the CSV file shows the shortest control time for each state pair: a row is `[s, e, $T^*_{s, e}$]`. Note that a zero value indicates infinity, i.e., `s` cannot robustly reach `e`.

Note that the results of the cardiac network and the TLGL network are too large (several GigaBytes) to upload to GitHub.
Please run the code to produce the results locally.
