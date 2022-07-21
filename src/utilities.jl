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

function get_clamped_nnet(infile, lbs, ubs)
    network = read_nnet(infile)

    layers = Vector{Layer}()
    for layer in network.layers
        push!(layers, layer)
    end

    N = length(lbs)
    identity = zeros(N, N)
    for i = 1:N
        identity[i, i] = 1.0
    end

    # Extra layer 0 (gets combined with current last bias)
    last_layer = Layer(layers[end].weights,
                        layers[end].bias .- lbs,
                        ReLU())
    layers[end] = last_layer

    # Extra layer 1
    push!(layers, Layer(-identity,
                        ubs .- lbs,
                        ReLU()))

    # Extra layer 2
    push!(layers, Layer(-identity,
                        ubs,
                        Id()))
    
    clamped_network = Network(layers)
    #write_nnet(outfile, clamped_network)
    return clamped_network
end

function extend_dims(A,which_dim)
    s = [size(A)...]
    insert!(s,which_dim,1)
    return reshape(A, s...)
end
