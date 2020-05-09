export MtlComputeCommandEncoder, set!, setbuffer!, dispatchThreads!, endEncoding!

const MTLComputeCommandEncoder = Ptr{MtComputeCommandEncoder}

mutable struct MtlComputeCommandEncoder <: MtlCommandEncoder
    handle::MTLComputeCommandEncoder
    cmdbuf::MtlCommandBuffer
end

Base.convert(::Type{MTLComputeCommandEncoder}, q::MtlComputeCommandEncoder) = q.handle
Base.unsafe_convert(::Type{MTLComputeCommandEncoder}, q::MtlComputeCommandEncoder) = convert(MTLComputeCommandEncoder, q.handle)

function MtlComputeCommandEncoder(cmdbuf::MtlCommandBuffer; dispatch_type::Union{Nothing,MtDispatchType} = nothing)
    if isnothing(dispatch_type)
        handle = mtNewComputeCommandEncoder(cmdbuf)
    else
        handle = mtNewComputeCommandEncoderWithDispatchtype(cmdbuf, dispatchtype)
    end
    obj = MtlComputeCommandEncoder(handle, cmdbuf)
    #finalizer(unsafe_destroy!, obj)
    return obj
end

set_function!(cce::MtlComputeCommandEncoder, pip::MtlComputePipelineState) =
    mtComputeCommandEncoderSetComputePipelineState(cce, pip)

set_buffer!(cce::MtlComputeCommandEncoder, buf::Union{MtlBuffer,MtlPtr}, offset::Integer, index::Integer) =
    mtComputeCommandEncoderSetBufferOffsetAtIndex(cce, buf, offset, index)
set_bufferoffset!(cce::MtlComputeCommandEncoder, offset::Integer, index::Integer) =
    mtComputeCommandEncoderBufferSetOffsetAtIndex(cce, offset, index)
set_buffers!(cce::MtlComputeCommandEncoder, bufs::Vector{MtlBuffer},
             offsets::Vector{Int}, indices::UnitRange{Int}) =
    mtComputeCommandEncoderSetBuffersOffsetsWithRange(cce, handle_array(bufs), offsets, indices .- 1)
set_buffers!(cce::MtlComputeCommandEncoder, bufs::Vector{MtlPtr{T}},
             offsets::Vector{Int}, indices::UnitRange{Int}) where {T} =
    mtComputeCommandEncoderSetBuffersOffsetsWithRange(cce, bufs, offsets, indices .- 1)

dispatchThreads!(cce::MtlComputeCommandEncoder, gridSize::MtSize, threadGroupSize::MtSize) =
    mtComputeCommandEncoderDispatchThreadgroups_threadsPerThreadgroup(cce, gridSize, threadGroupSize)

#####
# encode in the Command Encoder
function MtlComputeCommandEncoder(f::Base.Callable, cmdbuf::MtlCommandBuffer; kwargs...)
    encoder = MtlComputeCommandEncoder(cmdbuf; kwargs...)
    f(encoder)
    close(encoder)
    return encoder
end

append_current_function!(cce::MtlComputeCommandEncoder, gridSize::MtSize, threadGroupSize::MtSize) =
    dispatchThreads!(cce, gridSize, threadGroupSize)