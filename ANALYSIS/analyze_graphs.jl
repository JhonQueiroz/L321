using ArgParse
using CSV
using DataFrames
using Graphs

const GRAPH_EXTENSIONS = Set([".txt"])

function parse_command_line()
    settings = ArgParseSettings(
        description = "Analisa uma base de grafos em formato de lista de arestas e gera um CSV com metricas basicas."
    )

    @add_arg_table settings begin
        "--base"
            help = "Pasta raiz da base de grafos."
            arg_type = String
            default = joinpath("BASE", "AMOSTRA")

        "--output"
            help = "Arquivo CSV de saida."
            arg_type = String
            default = joinpath("ANALYSIS", "graph_metrics_amostra.csv")

        "--extensions"
            help = "Extensoes consideradas como instancias, separadas por virgula."
            arg_type = String
            default = ".txt"
    end

    return parse_args(settings)
end

function read_graph(filename::String)
    open(filename, "r") do io
        first_data_line = ""

        while !eof(io)
            line = strip(readline(io))
            if !isempty(line) && !startswith(line, "#")
                first_data_line = line
                break
            end
        end

        isempty(first_data_line) && error("Arquivo vazio ou sem cabecalho: $filename")

        header = split(first_data_line)
        length(header) < 2 && error("Cabecalho invalido em $filename. Esperado: n m")

        n = parse(Int, header[1])
        expected_m = parse(Int, header[2])
        graph = SimpleGraph(n)
        loops_ignored = 0
        invalid_edges = 0
        duplicated_edges = 0
        data_edges = 0

        for raw_line in eachline(io)
            line = strip(raw_line)
            if isempty(line) || startswith(line, "#")
                continue
            end

            parts = split(line)
            length(parts) < 2 && continue

            u = parse(Int, parts[1])
            v = parse(Int, parts[2])
            data_edges += 1

            if u == v
                loops_ignored += 1
                continue
            end

            if !(1 <= u <= n) || !(1 <= v <= n)
                invalid_edges += 1
                continue
            end

            if has_edge(graph, u, v)
                duplicated_edges += 1
                continue
            end

            add_edge!(graph, u, v)
        end

        return graph, expected_m, data_edges, loops_ignored, invalid_edges, duplicated_edges
    end
end

function safe_density(graph::SimpleGraph)
    n = nv(graph)
    return n <= 1 ? 0.0 : (2.0 * ne(graph)) / (n * (n - 1))
end

function graph_diameter(graph::SimpleGraph)
    nv(graph) == 0 && return missing
    is_connected(graph) || return missing

    n = nv(graph)
    max_distance = 0

    for source in 1:n
        distances = gdistances(graph, source)
        max_distance = max(max_distance, maximum(distances))
    end

    return max_distance
end

function graph_metrics(path::String, base_dir::String)
    graph, _, _, _, _, _ = read_graph(path)
    degrees = degree(graph)
    n = nv(graph)
    m = ne(graph)

    relative_path = relpath(path, base_dir)
    path_parts = splitpath(relative_path)
    graph_name = splitext(basename(path))[1]
    family = length(path_parts) >= 2 ? path_parts[1] : ""

    return (
        familia = family,
        grafo = graph_name,
        numero_vertices = n,
        numero_arestas = m,
        densidade = safe_density(graph),
        grau_maximo = isempty(degrees) ? 0 : maximum(degrees),
        diametro = graph_diameter(graph)
    )
end

function collect_instances(base_dir::String, extensions::Set{String})
    instances = String[]

    for (root, _, files) in walkdir(base_dir)
        for file in files
            ext = lowercase(splitext(file)[2])
            if ext in extensions
                push!(instances, joinpath(root, file))
            end
        end
    end

    sort!(instances)
    return instances
end

function main()
    args = parse_command_line()
    base_dir = abspath(args["base"])
    output_file = abspath(args["output"])
    extensions = Set(lowercase.(strip.(split(args["extensions"], ","))))

    isdir(base_dir) || error("Pasta base nao encontrada: $base_dir")

    instances = collect_instances(base_dir, extensions)
    isempty(instances) && error("Nenhum grafo encontrado em $base_dir com extensoes: $(join(sort(collect(extensions)), ", "))")

    rows = NamedTuple[]
    total = length(instances)
    skipped = 0

    for (idx, path) in enumerate(instances)
        println("[INFO] ($idx/$total) analisando $(relpath(path, base_dir))")
        try
            push!(rows, graph_metrics(path, base_dir))
        catch err
            skipped += 1
            println("[WARN] ignorando $(relpath(path, base_dir)): $err")
        end
    end

    isempty(rows) && error("Nenhum grafo valido encontrado em $base_dir")

    mkpath(dirname(output_file))
    df = DataFrame(rows)
    CSV.write(output_file, df)

    println("[DONE] $(length(rows)) grafos analisados")
    println("[DONE] $skipped arquivos ignorados")
    println("[DONE] CSV gerado em: $output_file")
end

main()
