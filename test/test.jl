using Test
using BinaryUtils

@testset "BinaryUtils" begin

    @testset "bin2dec" begin
        # Bool単体
        @test bin2dec(true) == 1
        @test bin2dec(false) == 0

        # ベクトル (MSB左, デフォルト)
        @test bin2dec(Bool[1, 0, 1]) == 5
        @test bin2dec(Bool[1, 1, 1, 1]) == 15
        @test bin2dec(Bool[0, 0, 0]) == 0

        # ベクトル (MSB右)
        @test bin2dec(Bool[1, 0, 1]; msb=:right) == 5
        @test bin2dec(Bool[1, 1, 0]; msb=:right) == 3

        # 不正なmsb
        @test_throws ArgumentError bin2dec(Bool[1, 0]; msb=:invalid)

        # 行列 (各列が1つの2進数)
        bins = Bool[1 0; 0 1; 1 0]  # 列1: [1,0,1]=5, 列2: [0,1,0]=2
        @test bin2dec(bins) == [5, 2]
    end

    @testset "dec2bin / dec2bin!" begin
        # 基本変換
        @test dec2bin(5) == Bool[1, 0, 1]
        @test dec2bin(0) == Bool[0]
        @test dec2bin(15) == Bool[1, 1, 1, 1]

        # パディング
        @test dec2bin(5; pad=8) == Bool[0, 0, 0, 0, 0, 1, 0, 1]

        # rev=true (MSB右)
        @test dec2bin(5; rev=true) == Bool[1, 0, 1]

        # in-place版
        buf = zeros(Bool, 4)
        dec2bin!(buf, 5)
        @test buf == Bool[0, 1, 0, 1]
    end

    @testset "shift!" begin
        # 右シフト
        arr = [1, 2, 3, 4, 5]
        shift!(arr, 2)
        @test arr == [0, 0, 1, 2, 3]

        # 左シフト
        arr = [1, 2, 3, 4, 5]
        shift!(arr, -2)
        @test arr == [3, 4, 5, 0, 0]

        # シフト0 (変化なし)
        arr = [1, 2, 3]
        shift!(arr, 0)
        @test arr == [1, 2, 3]

        # 配列長以上のシフト (全てゼロ)
        arr = [1, 2, 3]
        shift!(arr, 5)
        @test arr == [0, 0, 0]
    end

    @testset "oct2dec" begin
        @test oct2dec(10) == 8
        @test oct2dec(77) == 63
        @test oct2dec(0) == 0
    end

    @testset "oct2bin / bin2oct" begin
        # oct2bin
        b = oct2bin(7; len=3)
        @test b == Bool[1, 1, 1]

        b = oct2bin(10; len=4)
        @test bin2dec(b) == 8  # 8進の10 = 10進の8

        # bin2oct
        @test bin2oct(Bool[1, 1, 1]) == 7
        @test bin2oct(Bool[1, 0, 1, 0]) == 12  # 10進10 -> 8進12

        # ラウンドトリップ
        original = 75  # 8進数
        b = oct2bin(original; len=6)
        @test bin2oct(b) == original
    end

    @testset "grayenc" begin
        # 整数版
        @test grayenc(0) == 0
        @test grayenc(1) == 1
        @test grayenc(2) == 3
        @test grayenc(3) == 2
        @test grayenc(4) == 7
        @test grayenc(5) == 6
        @test grayenc(6) == 4
        @test grayenc(7) == 5

        # 配列版
        @test grayenc([0, 1, 2, 3]) == [grayenc(0), grayenc(1), grayenc(2), grayenc(3)]
    end

    @testset "grayenc!" begin
        # 整数配列版
        expected = [grayenc(0), grayenc(1), grayenc(2), grayenc(3)]
        arr = [0, 1, 2, 3]
        grayenc!(arr)
        @test arr == expected

        # Bool配列版 (MSB左)
        bin = Bool[1, 1, 0]  # 6
        grayenc!(bin)
        @test bin == Bool[1, 0, 0]
    end

end
