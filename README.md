# GA-L321

Algoritmo Genético para o Problema da Rotulação L(3,2,1) em grafos.

Este projeto implementa um algoritmo genético baseado em permutação (PBGA), usando um algoritmo guloso como função de avaliação. O fitness de cada indivíduo é o `span` da rotulação produzida, isto é, o maior rótulo atribuído. O objetivo é minimizar esse valor.

## Características

- Representação por permutação dos vértices.
- Seleção por torneio binário (`k = 2`) como operador padrão.
- Cruzamento Order Crossover (`OX`) de dois pontos como operador padrão.
- Mutação por troca (`swap`) como operador padrão.
- Elitismo com preservação parcial da população.
- Pré-cálculo dos conjuntos de vértices a distância 1, 2 e 3.
- Execuções independentes por instância, com exportação de resultados em CSV.

O código também contém operadores alternativos:

- Seleção por roleta em [GA/selection_ops.jl](GA/selection_ops.jl).
- Cruzamento PMX em [GA/crossover_ops.jl](GA/crossover_ops.jl).
- Mutação por inversão em [GA/mutation_ops.jl](GA/mutation_ops.jl).

## Requisitos

O projeto foi desenvolvido em Julia e depende dos pacotes declarados em [Project.toml](Project.toml):

- `Graphs.jl`
- `ArgParse.jl`
- `CSV.jl`
- `DataFrames.jl`

`Random` e `Base.Threads` fazem parte da biblioteca padrão do Julia.

## Ambiente Julia

Com Julia instalado, entre na pasta do projeto e ative o ambiente local:

```bash
julia --project=.
```

Na primeira execução, resolva e instale as dependências:

```bash
julia --project=. -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
```

Esse comando também preenche o [Manifest.toml](Manifest.toml) com as versões exatas dos pacotes instalados. O `Project.toml` declara as dependências diretas do projeto; o `Manifest.toml` registra a resolução completa para tornar os experimentos mais reprodutíveis.

## Estrutura do projeto

- `BASE/`: conjunto completo de instâncias.
- `GA/main.jl`: script principal de linha de comando.
- `GA/ga.jl`: implementação do algoritmo genético.
- `GA/selection_ops.jl`: operadores de seleção.
- `GA/crossover_ops.jl`: operadores de cruzamento.
- `GA/mutation_ops.jl`: operadores de mutação.
- `GREEDY/greedy.jl`: algoritmo guloso L(3,2,1) e pré-cálculo de distâncias.
- `RESULTS/GA/`: resultados do algoritmo genético principal.
- `RESULTS/BRKGA/`: resultados do BRKGA.
- `run_ga.ps1`: script de execução em lote do GA para PowerShell no Windows.
- `run_brkga.ps1`: script de execução em lote do BRKGA para PowerShell no Windows.

## Análise estrutural da base

Para gerar um CSV com métricas dos grafos da base final:

```bash
julia --project=. ANALYSIS/analyze_graphs.jl --base BASE/FINAL --output RESULTS/graph_metrics.csv
```

O CSV inclui a família, o nome do grafo, o número de vértices, o número de
arestas, a densidade, o grau máximo e o diâmetro. Para grafos desconexos, o
diâmetro fica vazio no CSV.

## Formato das instâncias

As instâncias são arquivos `.txt` em formato de lista de arestas:

```text
n m
u1 v1
u2 v2
...
um vm
```

A primeira linha contém o número de vértices `n` e o número de arestas `m`. As linhas seguintes contêm uma aresta por linha.

## Execução de uma instância

Exemplo:

```bash
julia --project=. --threads auto GA/main.jl \
  --instance BASE/sd_3_100.txt \
  --seed 1234 \
  --pop_factor 2 \
  --crossover_rate 0.90 \
  --mutation_rate 0.20 \
  --elitism_rate 0.10 \
  --max_gen 200 \
  --max_stagnation 50 \
  --trials 30 \
  --output RESULTS/GA/sd_3_100.csv
```

O script gera dois arquivos:

- `sd_3_100.csv`: resumo por tentativa independente.
- `sd_3_100_curve.csv`: melhor `span` por geração em cada tentativa.

## Execução em lote

### Windows / PowerShell

No Windows, use o script [run_ga.ps1](run_ga.ps1). Ele percorre recursivamente as instâncias `.txt`,
cria a mesma estrutura de subpastas em `RESULTS/GA` e pula instâncias que já possuem CSV de saída.

Execução padrão, usando `BASE/` como entrada:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_ga.ps1
```

Parâmetros principais do script:

- `-BaseDir`: pasta raiz das instâncias. Padrão: `BASE`.
- `-RootOutputDir`: pasta raiz dos resultados. Padrão: `RESULTS\GA`.
- `-JuliaThreads`: número de threads usado por `julia --threads`. Padrão: `auto`.
- `-Seed`: semente base. Padrão: `1234`.
- `-PopFactor`: denominador para `popsize = floor(n/pop_factor)`. Padrão: `2`.
- `-CrossoverRate`: taxa de cruzamento. Padrão: `0.90`.
- `-MutationRate`: taxa de mutação. Padrão: `0.20`.
- `-ElitismRate`: taxa de elitismo. Padrão: `0.10`.
- `-MaxGen`: número máximo de gerações. Padrão: `200`.
- `-MaxStagnation`: número máximo de gerações sem melhoria da solução global. Padrão: `100`.
- `-Trials`: número de execuções independentes por instância. Padrão: `30`.

O script procura `julia` no `PATH`. Se o `PATH` apontar apenas para o alias do
`Microsoft\WindowsApps`, ele também tenta localizar o executável instalado pelo `juliaup`
em `$HOME\.julia\juliaup`.

### BRKGA / PowerShell

Para o BRKGA, use [run_brkga.ps1](run_brkga.ps1). Ele percorre recursivamente as instâncias `.txt`,
grava um CSV por instância em `RESULTS/BRKGA` e pula instâncias que já possuem arquivo de saída.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_brkga.ps1
```

## Observações

- O projeto ainda não possui testes automatizados.
- Para reproduzir resultados em outra máquina, mantenha o `Project.toml` e gere/compartilhe um `Manifest.toml` completo a partir do comando de ambiente Julia.
