---
layout: post
title: "ARM64 汇编指令总结"
date: 2019-01-24 06:35:54 -0800
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

ARMv8 指令集可以大致分为三类:A64 指令集、A32&T32 指令集。

ARM 汇编真的太痛苦了。。。一个命令一个命令的学习记录吧

<!--more-->

指令格式：

`<Opcode>[<Cond>]<S> <Rd>, <Rn> [.<Opcode2>]`

* 其中尖括号的选项是必须的，花括号是可选的。
* A32 : Rd==>{R0-R14}
* A64 : Rd==>Xt==>{X0-X30}

| 标识符| 备注  |
| :---: | :---: |
| Opcode | 操作码，也就是助记符，说明指令需要执行的操作类型 |
| Cond | 指令执行条件码，在编码中占4bit, 0b000-0b1110 |
| S | 条件码设置项，决定本次指令是否影响 PSTATE 寄存器响应状态位值 |
| Rd/Xt | 目标寄存器，A32 指令可以选择 R0-R14，T32指令大部分只能选择R0-R7,A64指令可以选择X0-X30 或 W0-W30 |
| Rn/Xn | 第一个操作数的寄存器，和 Rd 一样，不同指令有不同要求 |
| Opcode2 | 第二个操作数，可以是立即数，寄存器Rm 和寄存器移位方式(Rm, #shift) |


## SQDMULH(vector/by element)

Signed saturating Doubling Multiply return High half.该指令会将两个源寄存器中对应的元素相乘，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQDMULH <V><d>, <V><n>, <V><m>`

Vector:

`SQDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

* `<Vd>`:目的寄存器 SIMD&FP 
* `<Vn>`:第一个源寄存器 SIMD&FP 
* `<Vm>`:第二个源寄存器 SIMD&FP 
* `<T>`:4H/8H/2S/4S 中的一个

示例

* sqdmulh v0.8h, v0.8h, v30.8h 


Signed saturation Doubling Multiply return High half(by element).该指令将第一个源寄存器的每个矢量元素乘以第二个源寄存器的某个特定矢量元素，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQDMULH <V><d>, <V><n>, <Vm>.<Ts>[<index>]`

Vector:

`SQDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<Ts>[<index>]`

## SQRDMULH(vector/by element)

Signed saturating Rounding Doubling Multiply returning High half.该指令会将两个源寄存器中对应的元素相乘，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQRDMULH <V><d>, <V><n>, <V><m>`

Vector:

`SQRDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`


Scalar:

`SQRDMULH <V><d>, <V><n>, <Vm>.<Ts>[<index>]`

Vector:

`SQRDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<Ts>[<index>]`

## SQRSHRUN, SQRSHRUN2

Signed saturating Rounded Shift Right Unsigned Narrow(immediate). 

Scalar:

`SQRSHRUN <Vb><d>, <Va><n>, #<shift>`

示例：

* sqrshrun v0.8b, v1.8h, #5

Vector:

`SQRSHRUN{2} <Vd>.<Tb>, <Vn>.<Ta>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 的名字。
* `<Tb>`:8B/16B/4H/8H/2S/4S。
* `<Vn>`:源寄存器 SIMD&FP 的名字。
* `<Ta>`:8H/4S/2D。

示例：

* sqrshrun2 v0.16b, v1.8h, #5

## SQSHRUN, SQSHRUN2

Signed saturating Shift Right Unsigned Narror(immediate).

Scalar:

`SQSHRUN <Vb><d>, <Va><n>, #<shift>`

Vector:

`SQSHRUN{2} <Vd>.<Tb>, <Vn>.<Ta>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 的名字。
* `<Tb>`:8B/16B/4H/8H/2S/4S。
* `<Vn>`:源寄存器 SIMD&FP 的名字。
* `<Ta>`:8H/4S/2D。

示例：

* sqrshrun2 v0.16b, v1.8h, #5

## SHL

Shift Left(immediate)。

Scalar:

`SHL <V><d>, <V><n>, #<shift>`

Vector:

`SHL <Vd>.<T>, <Vn>.<T>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 名字。
* `<T>`:8B/16B/4H/8H/2S/4S/2D。
* `<Vn>`:源寄存器 SIMD&FP 名字。

## SHLL, SHLL2

Shift Left Long(by element size)。

Vector:

`SHLL{2} <Vd>.<Ta>, <Vn>.<Tb>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 的名字。
* `<Ta>`:8H/4S/2D。
* `<Vn>`:源寄存器 SIMD&FP 名字。
* `<Tb>`:8B/16B/4H/8H/2S/4S。

* shll  v28.8h, v30.8b,  #8
* shll2 v29.8h, v30.16b, #8

## SSHLL, SSHLL2

Signed Shift Left Long(immediate)。

`SSHLL{2} <Vd>.<Ta>, <Vn>.<Tb>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 的名字。
* `<Ta>`:8H/4S/2D。
* `<Vn>`:源寄存器 SIMD&FP 名字。
* `<Tb>`:8B/16B/4H/8H/2S/4S。

## USHLL, USHLL2

Unsigned Shift Left Long(immediate)。

`USHLL{2} <Vd>.<Ta>, <Vn>.<Tb>, #<shift>`

* `<Vd>`:目的寄存器 SIMD&FP 的名字。
* `<Ta>`:8H/4S/2D。
* `<Vn>`:源寄存器 SIMD&FP 名字。
* `<Tb>`:8B/16B/4H/8H/2S/4S。

## TRN1 & TRN2

TRN1:转置向量 Transpose vector(primary), 该指令从零开始读取两个源寄存器 SIMD&FP 的相应偶数向量元素，并将每个结果放到向量的连续元素，并将向量写到目的寄存器中。第一个源寄存器中的向量元素被放到目的寄存器的偶数元素位置，第二个源寄存器中的向量元素放到目的寄存器的奇数元素位置。

Advanced SIMD variant

`TRN1 <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

* `<Vd>`:目的寄存器 SIMD&FP 名字。
* `<T>`:8B/16B/4H/8H/2S/4S/2D。
* `<Vn>`:第一个源寄存器 SIMD&FP 名字。
* `<Vm>`:第二个源寄存器 SIMD&FP 名字。

示例：

* trn1 v4.2d, v4.2d, v5.2d

TRN2:转置向量 Transpose vectors(secondary)。该指令读取两个源寄存器 SIMD&FP 的相应奇数向量元素，并将每个结果放到向量的连续元素，并将向量写到目的寄存器中。第一个源寄存器中的向量元素被放到目的寄存器的偶数元素位置，第二个源寄存器中的向量元素放到目的寄存器的奇数元素位置。

Advanced SIMD variant

`TRN2 <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

* `<Vd>`:目的寄存器 SIMD&FP 名字。
* `T`:8B/16B/4H/8H/2S/4S/2D。
* `<Vn>`:第一个源寄存器 SIMD&FP 名字。
* `<Vm>`:第二个源寄存器 SIMD&FP 名字。

示例：

* trn2 v7.2s, v5.2s, v7.2s

{% img /images/neon_coding/trn.png %}

## SXTL, SXTL2

SXTL:Signed extend Long,该指令

Vector:

`SXTL{2} <Vd>.<Ta>, <Vn>.<Tb>` 等同于 `SSHLL{2} <Vd>.<Ta>, <Vn>.<Tb>, #0`

示例：

* sxtl v0.8h, v0.8b

## UXTL, UXTL2

UXTL:Unsigned extend Long.

Vector:

`UXTL{2} <Vd>.<Ta>, <Vn>.<Tb>` 等同于 `USHLL{2} <Vd>.<Ta>, <Vn>.<Tb>, #0`

示例：

* uxtl v4.8h, v4.8b

## EXT

EXT:Extract vector from pair of vectors.

Advanced SIMD variant

`EXT <Vd>.<T>, <Vn>.<T>, <Vm>.<T>, #<index>`

{% img /images/neon_coding/ext.png %}

示例：

* ext v5.16b, v4.16b, v4.16b, #2

## BFM, UBFM, SBFM(Bitfield move指令)

BFM:

32-bit variant

`BFM <Wd>, <Wn>, #<immr>, #<imms>`

64-bit variant

`BFM <Xd>, <Xn>, #<immr>, #<imms>`

SBFM:

32-bit variant

`SBFM <Wd>, <Wn>, #<immr>, #<imms>`

64-bit variant

`SBFM <Xd>, <Xn>, #<immr>, #<imms>`


UBFM:

32-bit variant

`UBFM <Wd>, <Wn>, #<immr>, #<imms>`

64-bit variant

`UBFM <Xd>, <Xn>, #<immr>, #<imms>`

示例：

* ubfm w9, w5, #7, #13

## SRSHR

SRSHR:Signed Rounding Shift Right(immediate)。

Scalar variant:

`SRSHR <V><d>, <V><n>, #<shift>`

Vector:

`SRSHR <Vd>.<T>, <Vn>.<T>, #<shift>`

示例：

* srshr v24.8h, v24.8h, #2


