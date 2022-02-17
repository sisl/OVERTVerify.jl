# Generate a metric network which has ReLU activation on its ouput layer.
# the output will be interpreted as the diagonal of our M matrix
function random_network(layer_sizes, activations; do_round=false)
    layers = Layer[]
    for i = 1:(length(layer_sizes)-1)
        layer_in = layer_sizes[i]
        layer_out = layer_sizes[i+1]
        weights = randn(layer_out, layer_in)
        bias = randn(layer_out)
        # All ReLU including the last layer because we want
        # the output to be >= 0
        if do_round
            weights = round.(weights, digits=3)
            bias = round.(bias, digits=3)
        end
            
        push!(layers, Layer(weights, bias, activations[i]))
    end
    return Network(layers)
end
