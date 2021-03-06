using Distributions


function test_gaussian_recon_loss_layer(backend::Backend, T, eps)
    println("-- Testing GaussianReconLossLayer on $(typeof(backend)){$T}...")

    ############################################################
    # Prepare Data for Testing
    ############################################################
    dims = (3, 4, 5)
    tensor_dim = length(dims)
    p, n = prod(dims[1:end-1]), dims[end]
    println("        > $dims")

    ############################################################
    # Setup
    ############################################################
    layer = GaussianReconLossLayer(bottoms=[:mu, :sigma, :x])

    mu = rand(p, n)  # sigmoid output is in [0, 1]
    sigma = max(1e-2, 0.2rand(p, n)) # PReLU output is > 0
    x = max(1e-2, rand(dims))  # normalized pixel values are in [0, 1]

    inputs = Blob[
        make_blob(backend, convert(Array{T}, mu)),
        make_blob(backend, convert(Array{T}, sigma)),
        make_blob(backend, convert(Array{T}, x))]

    diffs = Blob[
        make_blob(backend, rand(T, size(inputs[1]))),  # gets overwritten
        make_blob(backend, rand(T, size(inputs[2]))),  # gets overwritten
        NullBlob()]  # the data is fixed

    state = setup(backend, layer, inputs, diffs)

    ############################################################
    # Forward Propagation
    ############################################################
    forward(backend, state, inputs)

    loss = 0.
    for i in 1:n
        Xi_given_zi = MvNormal(mu[:, i], sigma[:, i])  # a random var
        xi = slicedim(x, tensor_dim, i)[:]  # an instance
        loss -= logpdf(Xi_given_zi, xi)
    end
    loss /= n
    @test loss >= 0

    info("expected $loss; got $(state.loss)")
    @test -eps < loss - state.loss < eps

    ############################################################
    # Backward Propagation
    ############################################################
    backward(backend, state, inputs, diffs)

    for i in 1:2
        input_i = Array(T, size(inputs[i]))
        copy!(input_i, inputs[i])
        diff_i = Array(T, size(diffs[i]))
        copy!(diff_i, diffs[i])

        for k in 1:p, j in 1:n
            x0 = input_i[k, j]
            function f(x::FloatingPoint)
                input_i[k, j] = x
                copy!(inputs[i], input_i)
                forward(backend, state, inputs)
                input_i[k, j] = x0
                copy!(inputs[i], input_i)
                state.loss
            end
            test_deriv(f, x0, diff_i[k, j])
        end
    end

    ############################################################
    # Shutdown
    ############################################################
    shutdown(backend, state)
end

function test_gaussian_recon_loss_layer(backend::Backend)
    test_gaussian_recon_loss_layer(backend, Float64, 1e-8)
end

if test_cpu
    test_gaussian_recon_loss_layer(backend_cpu)
end
if test_gpu
    test_gaussian_recon_loss_layer(backend_gpu)
end

