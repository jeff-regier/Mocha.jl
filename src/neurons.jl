export ActivationFunction
export Neurons

export forward, backward

############################################################
# Each activation function / neuron should be a sub type
# of ActivationFunction and should implement the following
# methods.
#
# - forward(backend :: Backend, neuron :: MyActivationFunction, output :: Blob)
#   Update the output blob by the activation function. Computation should be done in-place.
#   Note we call is "output" because an activation function is applied to the "output" of
#   a layer.
#
# - backward(backend :: Backend, neuron :: MyActivationFunction, output :: Blob, gradient :: Blob)
#   The gradient blob contains the gradient with respect to the output of the activation
#   function, update (IN-PLACE) the gradient to be with respect to the output of the activation
#   function.
############################################################

abstract ActivationFunction

############################################################
# A module to hold built-in activation functions to avoid
# messy namespace
############################################################
module Neurons
using ..Mocha.ActivationFunction
# Identity
type Identity <: ActivationFunction
end

# Rectified-Linear: ReLU(eps)(x) = max(x,eps)
type ReLU <: ActivationFunction
  epsilon::Float64 # optional floor value, default zero
end
ReLU() = ReLU(0.0)

# Exponential: Exponential(x) = exp(x)
type Exponential <: ActivationFunction
end

# Leaky Rectified-Linear: LReLU(x) = x > 0 ? x : 0.01x
type LReLU <: ActivationFunction
end

# Exponential Rectified-Linear
type ExpReLU <: ActivationFunction
    t::AbstractFloat
end

# Epsilon Rectified-Linear
type EpsReLU <: ActivationFunction
end

# Sigmoid: Sigmoid(x) = 1 / (1 + exp(-x))
type Sigmoid <: ActivationFunction
end

# PSigmoid: Sigmoid(x) + epsilon
type PSigmoid <: ActivationFunction
end

# Sigmoid: Tanh(x) = (1 + exp(-2x)) / (1 + exp(-2x))
type Tanh <: ActivationFunction
end

end # module Neurons

############################################################
# Identity
############################################################
function forward(backend :: Backend, neuron :: Neurons.Identity, output :: Blob)
  # do nothing
end
function backward(backend :: Backend, neuron :: Neurons.Identity, output :: Blob, gradient :: Blob)
  # do nothing
end

############################################################
# Rectified-Linear
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.ReLU, output :: Blob)
  @simd for i = 1:length(output.data)
    @inbounds output.data[i] = max(neuron.epsilon, output.data[i])
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.ReLU, output :: Blob, gradient :: Blob)
  @simd for i = 1:length(output.data)
    @inbounds gradient.data[i] *= (output.data[i] > neuron.epsilon)
  end
end

############################################################
# Leaky Rectified-Linear
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.LReLU, output :: Blob)
  @simd for i = 1:length(output.data)
    @inbounds output.data[i] = output.data[i] > 0 ? output.data[i] : 0.01 * output.data[i]
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.LReLU, output :: Blob, gradient :: Blob)
  @simd for i = 1:length(output.data)
    @inbounds gradient.data[i] *= ((output.data[i] > 0) + 0.01 * (output.data[i] <= 0))
  end
end

############################################################
# Exp Rectified-Linear
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.ExpReLU, output :: Blob)
  @simd for i = 1:length(output.data)
     @inbounds x = output.data[i]
     @inbounds output.data[i] = x < neuron.t ? exp(x) : exp(neuron.t) + (x - neuron.t)
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.ExpReLU, output :: Blob, gradient :: Blob)
  @simd for i = 1:length(output.data)
     @inbounds x = output.data[i]
     @inbounds gradient.data[i] *= x < neuron.t ? exp(x) : 1.
  end
end

############################################################
# Epsilon Rectified-Linear
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.EpsReLU, output :: Blob)
  @simd for i = 1:length(output.data)
     @inbounds x = output.data[i]
     @inbounds output.data[i] = 1e-3 + x * (x >= 0.)
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.EpsReLU, output :: Blob, gradient :: Blob)
  @simd for i = 1:length(output.data)
     @inbounds x = output.data[i]
     @inbounds gradient.data[i] *= (x < 0.)
  end
end

############################################################
# Sigmoid
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.Sigmoid, output :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds output.data[i] = 1 / (1 + exp(-output.data[i]))
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.Sigmoid, output :: Blob, gradient :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds gradient.data[i] *= output.data[i] * (1-output.data[i])
  end
end

############################################################
# PSigmoid
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.PSigmoid, output :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds output.data[i] = 1e-4 + 1 / (1 + exp(-output.data[i]))
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.PSigmoid, output :: Blob, gradient :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds gradient.data[i] *= output.data[i] * (1-output.data[i])
  end
end

############################################################
# Tanh
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.Tanh, output :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds output.data[i] = tanh(output.data[i])
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.Tanh, output :: Blob, gradient :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds gradient.data[i] *= (1 - output.data[i] * output.data[i])
  end
end

############################################################
# Exponential
############################################################
function forward(backend :: CPUBackend, neuron :: Neurons.Exponential, output :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds output.data[i] = exp(output.data[i])
  end
end
function backward(backend :: CPUBackend, neuron :: Neurons.Exponential, output :: Blob, gradient :: Blob)
  len = length(output)
  @simd for i = 1:len
    @inbounds gradient.data[i] *= output.data[i]
  end
end
