using BrkgaMpIpr
using Base.Threads

include("../GREEDY/greedy.jl")
include("instance.jl")
include("decoder.jl")

function csv_escape(value)
    text = string(value)
    if occursin('"', text)
        text = replace(text, "\"" => "\"\"")
    end
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
        return "\"" * text * "\""
    end
    return text
end

if length(ARGS) != 5
    error("Uso: julia --project=BRKGA BRKGA/main.jl <config_file> <instance_file> <seed> <generations> <output_csv>")
end

config_file   = ARGS[1]
instance_file = ARGS[2]
seed          = parse(Int, ARGS[3])
generations   = parse(Int, ARGS[4])
output_file   = ARGS[5]

instance = L321_Instance(instance_file)

brkga_data, control_params = build_brkga(
    instance,
    l321_decode!,
    MINIMIZE,
    seed,
    instance.num_nodes,
    config_file
)

#--------------- VIES DP BRKGA PADRAO P/ PAIS ----------------------
rho = 0.75
set_bias_custom_function!(brkga_data, x -> x == 1 ? rho : 1.0 - rho)

start_time = time()
initialize!(brkga_data)

evolve!(brkga_data, generations)
elapsed = time() - start_time

best_span = get_best_fitness(brkga_data)
best_order = sortperm(get_best_chromosome(brkga_data))
order_str = join(best_order, " ")
graph_name = basename(instance_file)
density = (2 * ne(instance.graph)) / (nv(instance.graph) * (nv(instance.graph) - 1))

header = "seed,graph,n,m,density,generations,bestSpan,time_sec,bestOrder"
row = join([
    csv_escape(seed),
    csv_escape(graph_name),
    csv_escape(instance.num_nodes),
    csv_escape(ne(instance.graph)),
    csv_escape(density),
    csv_escape(generations),
    csv_escape(best_span),
    csv_escape(elapsed),
    csv_escape(order_str)
], ",")

open(output_file, "w") do io
    write(io, header * "\n")
    write(io, row * "\n")
end

println("Best span: ", best_span)
println("Best order: ", best_order)
println("Output CSV: ", output_file)
