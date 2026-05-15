# IRACE configurations

This directory keeps separate irace configurations for each algorithm:

- `GA/`: tuning for the genetic algorithm in `GA/main.jl`.
- `BRKGA/`: tuning for the BRKGA in `BRKGA/main.jl`.

Run irace from inside the algorithm-specific directory so relative paths in
`instances.txt` resolve correctly.
