module BinaryUtils


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
    elseif msb == :right
        i = 0
        while (i < n)
            dec += bin[i+1] << i
            i += 1
        end
    else
        throw(ArgumentError("msb must be :left or :right, got $msb"))
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


# function bin2decs(bs::AbstractVector{T}, len) where {T<:Integer}
#     bs = reshape(bs, len, :)
#     decs = Array{Int16}(undef, size(bs, 2))
#     n = 1
#     for n in axes(bs, 2)
#         decs[n] = @views bin2dec(bs[:, n])
#     end
#     decs
# end
# function bin2decs!(decs::AbstractVector{<:Integer}, bins::AbstractVector{<:Bool}, len)
#     for n in eachindex(decs)
#         decs[n] = @views bin2dec(bins[n:n+len-1])
#     end
#     decs
# end

"""
    dec2bin!(bin::T, dec::Integer; rev=false) where {T<:AbstractArray}
10進数を2進数列に変換する
"""
function dec2bin!(bin::T, dec::Integer; rev=false) where {T<:AbstractArray}
    i = 1
    if !rev # MSBが左
        while dec > 0 && i <= length(bin)
            bin[end-i+1] = dec & 1
            dec >>= 1
            i += 1
        end
        # 残りのビットを0で埋める
        while i <= length(bin)
            bin[end-i+1] = 0
            i += 1
        end
    else # MSBが右
        while dec > 0 && i <= length(bin)
            bin[i] = dec & 1
            dec >>= 1
            i += 1
        end
        # 残りのビットを0で埋める
        while i <= length(bin)
            bin[i] = 0
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



"""
    shift!(arr::AbstractArray{T,1}, n::Integer) where T

配列のシフト
- n > 0: 右方向シフト（要素を右に移動）
- n < 0: 左方向シフト（要素を左に移動）
"""
function shift!(arr::AbstractArray{T,1}, n::Integer=1) where {T}
    len = length(arr) # 配列長
    zero_val = zero(T)
    if n > 0 # 右方向シフト
        if n < len
            for i in len:-1:1
                arr[i] = i > n ? arr[i-n] : zero_val
            end
        else
            arr[:] .= zero_val
        end
    elseif n < 0 # 左方向シフト
        abs_n = abs(n)
        if abs_n < len
            for i in 1:len
                arr[i] = i + abs_n <= len ? arr[i+abs_n] : zero_val
            end
        else
            arr[:] .= zero_val
        end
    end
    # n == 0 の場合は何もしない
    arr
end

"""
    oct2dec(x::Int, T=Int)

8進数->10進数に変換
"""
oct2dec(x::Int, T=Int) = string(x) |> x -> parse(T, x, base=8) # oct -> dec


"""
    oct2bin(oct::Integer; len=0, msb=:left)

8進数->2進数
"""
function oct2bin(oct::Integer; len=0, msb=:left)
    dec = parse(Int, string(oct), base=8) # 10進数変換
    # msbを文字列からシンボルに変換（後方互換性のため）
    msb_sym = msb isa String ? Symbol(msb) : msb
    dec2bin(dec, pad=len, rev=(msb_sym == :right)) # 2進数
end

"""
    bin2oct(bin::AbstractArray{Bool}; msb=:left, outtype="num")

2進数->8進数
"""
function bin2oct(bin::AbstractArray{Bool}; msb=:left, outtype="num")
    len = length(bin)
    oct = 0
    # 後方互換性のため文字列も受け入れる
    if (msb isa String && (msb == "right" || msb == "r")) || msb == :right
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
    grayenc!(bin::AbstractVector{<:Bool}, len::Integer=length(bin); msb=:left)

Gray符号化（in-place）
"""
function grayenc!(bin::AbstractVector{<:Bool}, len::Integer=length(bin); msb=:left)
    # 後方互換性のため文字列も受け入れる
    msb_sym = msb isa String ? Symbol(msb) : msb
    if msb_sym == :left
        for i in 2:len
            if bin[i-1] > 0
                bin[i] ⊻= bin[i-1]
            end
        end
    elseif msb_sym == :right
        for i in len-1:-1:1
            if bin[i+1] > 0
                bin[i] ⊻= bin[i+1]
            end
        end
    else
        throw(ArgumentError("msb must be :left or :right, got $msb"))
    end
    bin
end


"""
    grayenc(xs::AbstractArray{T}) where {T<:Integer}

Gray符号化する
"""
function grayenc(x::T, n=nothing) where {T<:Integer}
    isnothing(n) && (n = ndigits(x, base=2)) # bit length
    ptr = 1 << (n - 1) # 2^len
    for _ in 1:(n-1)
        x ⊻= (x & ptr) >> 1
        ptr >>= 1
    end
    x
end

function grayenc!(decs::AbstractArray{T}) where {T<:Integer}
    for (i, dec) in enumerate(decs)
        decs[i] = grayenc(dec)
    end
    return decs
end

grayenc(xs::AbstractArray{T}) where {T<:Integer} = grayenc!(copy(xs))




"""
    graydec(x::Integer)

Grey符号をデコードする
"""
function graydec(x::Integer)
    len = ndigits(x, base=2)

    n = 1
    for i in 1:(len-1)
        # 1bit shift -> xor
        x ⊻= (x & (n << i)) >> 1
    end
    x
end


end # module
