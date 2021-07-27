using OVERTVerify
using Documenter

makedocs(;
    modules=[OvertVerify],
    authors="Amir Maleki, Chelsea Sidrane",
    repo="https://github.com/sisl/OVERTVerify.jl/blob/{commit}{path}#L{line}",
    sitename="OVERTVerify.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://sisl.github.io/OVERTVerify.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/sisl/OVERTVerify.jl",
)
