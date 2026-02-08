module Binary


export bin2dec,
    bin2decs,
    dec2bin,
    dec2bin!,
    bin2oct,
    oct2bin,
    oct2dec,
    bin2sym,
    shift!,
    grayenc!,
    grayenc


"""
    bin2dec(bin::Bool)

2進数->10進数に変換
"""
bin2dec(bin::Bool) = Int(bin)

function bin2dec(bin::AbstractVector{T}; msb=:left) where {T<:Integer}
    n = length(bin)   # bit length
    dec = 0          # decimal
    if msb == :left
        i = 0
        while (i < n)
            dec += bin[end-i] << i
            i += 1
        end
    end
    return dec
end

function bin2dec(bins::AbstractMatrix{T}; msb=:left, axis=2) where {T<:Integer}
    decs = Vector{Int}(undef, size(bins, axis))

    for i = 1:size(bins, axis)
        bin = @views axis == 2 ? bins[:, i] : bins[i, :]
        decs[i] = bin2dec(bin, msb=msb)
    end
    decs
end


function bin2decs(bs::AbstractVector{T}, len) where {T<:Integer}
    bs = reshape(bs, len, :)
    decs = Array{Int16}(undef, size(bs, 2))
    n = 1
    for n in axes(bs, 2)
        decs[n] = @views bin2dec(bs[:, n])
    end
    decs
end
function bin2decs!(decs::AbstractVector{<:Integer}, bins::AbstractVector{<:Bool}, len)
    for n in eachindex(decs)
        decs[n] = @views bin2dec(bins[n:n+len-1])
    end
    decs
end


"""
    bin2sym(input, len)

ビット列をlenで区切った10進数列に変換
"""
function bin2sym(inputs, len)
    # 事前処理
    inputs = copy(inputs) # コピー生成
    rem = length(inputs) % len
    (rem > 0) && (append!(inputs, zeros(eltype(input), len - rem))) # ゼロ付加
    inputs = reshape(copy(inputs), len, :)
    # 変換
    outputs = zeros(Int64, size(inputs, 2))
    for i in axes(inputs, 2)
        outputs[i] = @views bin2dec(inputs[:, i])
    end
    return outputs
end

# 10進数を2進数列に変換する
# length(bin) > ndigits(dec,base=2)である必要がある
# digitsより早い!
function dec2bin!(bin::T, dec::Integer; rev=false) where {T<:AbstractArray}
    i = 1
    if !rev # MSBが左
        while dec > 0 || length(bin) >= i
            bin[end-i+1] = dec & 1
            dec >>= 1
            i += 1
        end
    else # MSBが右
        while dec > 0 && length(bin) >= i
            bin[i] = dec & 1
            dec >>= 1
            i += 1
        end
    end
end

function dec2bin(dec; pad=0, rev=false)
    l = ndigits(dec, base=2)
    len = ifelse(pad > l, pad, l)
    bin = Array{Bool}(undef, len)
    dec2bin!(bin, dec, rev=rev)
    bin
end


#=
function divide(arr::AbstractArray, n; start="right")
    len = length(arr)
    r = len % n # 商,余り
    x=[]; idx = 1
    if start == "right"
        if r > 0
            push!(x,arr[1:r])
            idx += r
        end
        for i in 1:div(len,n)
            push!(x,arr[idx:idx+n-1])
            idx += n
        end
    elseif start == "left"
        for i in 1:div(len,n)
            push!(x,arr[idx:idx+n-1])
            idx += n
        end
        if r > 0
            push!(x,arr[idx:idx+r-1])
        end
    end
    return x
end
=#

"""
    shift!(arr::AbstractArray{T,1}, m::Integer) where T

配列の右方向(+)シフト
"""
shift!(array::AbstractArray{Bool}, n=1) = shift!(array, n=n)

function shift!(arr::AbstractArray{T,1}, n::Integer) where {T}
    len = length(arr) # 配列長
    if n > 0 # 右方向シフト
        if n < len
            for i in len:-1:1
                arr[i] = i > shift ? arr[i-n] : 0
            end
        else
            arr[:] .= 0
        end
    else # 左方向シフト
        shif = abs(shift)
        if shift < len
            for i in 1:len
                arr[i] = i - n <= len ? arr[i-n] : 0
            end
        else
            arr[:] .= 0
        end
    end
    arr
end

"""
"""
oct2dec(x::Int, T=Int) = string(x) |> x -> parse(T, x, base=8) # oct -> dec


"""
    oct2bin(oct::Integer; len=0, msb="left")

8進数->2進数
"""
function oct2bin(oct::Integer; len=0, msb="left")
    dec = parse(Int, string(oct), base=8) # 10進数変換
    dec2bin(dec, msb=msb, len=len) # 2進数
end

"""
    bin2oct(bin::AbstractArray{Bool}; msb="left", outtype="num")

2進数->8進数
"""
function bin2oct(bin::AbstractArray{Bool}; msb="left", outtype="num")
    len = length(bin)
    oct = 0
    if msb == "right" || msb == "r"
        bin = reverse(bin)
    end
    base = 2 .^ [i for i in 2:-1:0] # 基底
    idx = len
    i = 0 # インデックス
    while (idx > 0)
        if idx > 2
            oct += 10^i * sum(bin[idx-2:idx] .* base)
            idx -= 3
            i += 1
        else
            oct += 10^i * sum(bin[1:idx] .* base[end-idx+1:end])
            idx -= 3
        end
    end
    if outtype == "str"
        oct = string(oct)
    end
    oct
end


"""
    grayenc!()
gray符号化
"""
function grayenc!(bin::AbstractVector{<:Bool}, len::Integer=length(bin); msb="left")
    if msb == "left"
        for i in 2:len
            if bin[i-1] > 0
                bin[i] ⊻= bin[i-1]
            end
        end
    elseif msb == "right"
        for i in len-1:-1:1
            if bin[i+1] > 0
                bin[i] ⊻= bin[i+1]
            end
        end
    end # if
    bin
end


"""
    grayenc

Gray符号化
"""
grayenc(bin::AbstractArray{T}) where {T<:Integer} = grayenc!(copy(bin))


function grayenc(dec::T, n=nothing) where {T<:Integer}
    isnothing(n) && (n = ndigits(dec, base=2)) # bit length
    ptr = 1 << (n - 1) # 2^len
    for i in 1:(n-1)
        dec ⊻= (dec & ptr) >> 1
        ptr >>= 1
    end
    dec
end
function grayenc!(decs::AbstractArray{T}) where {T<:Integer}
    for (i, dec) in enumerate(decs)
        decs[i] = grayenc(dec)
    end
    return decs
end

# Gray復号化
function graydec(dec::T) where {T<:Integer}
    len = ndigits(dec, base=2)
    n = 1
    for i in 1:(len-1)
        # 1bit shift -> xor
        dec ⊻= (dec & (n << i)) >> 1
    end
    dec
end


end # module
