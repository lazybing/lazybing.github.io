---
layout: post
title: "ARM64 汇编指令总结"
date: 2019-01-24 06:35:54 -0800
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

ARM 汇编真的太痛苦了。。。一个命令一个命令的学习记录吧

<!--more-->


## SQDMULH(vector)

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

## SQDMULH(by element)

Signed saturation Doubling Multiply return High half(by element).该指令将第一个源寄存器的每个矢量元素乘以第二个源寄存器的某个特定矢量元素，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQDMULH <V><d>, <V><n>, <Vm>.<Ts>[<index>]`

Vector:

`SQDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<Ts>[<index>]`

## SQRDMULH(vector)

Signed saturating Rounding Doubling Multiply returning High half.该指令会将两个源寄存器中对应的元素相乘，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQRDMULH <V><d>, <V><n>, <V><m>`

Vector:

`SQRDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

## SQRDMULH(by element)

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

TRN1:Transpose vector(primary)。

Advanced SIMD variant

`TRN1 <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

* `<Vd>`:目的寄存器 SIMD&FP 名字。
* `<T>`:8B/16B/4H/8H/2S/4S/2D。
* `<Vn>`:第一个源寄存器 SIMD&FP 名字。
* `<Vm>`:第二个源寄存器 SIMD&FP 名字。

示例：

* trn1 v4.2d, v4.2d, v5.2d

TRN2:Transpose vectors(secondary)。

Advanced SIMD variant

`TRN2 <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

* `<Vd>`:目的寄存器 SIMD&FP 名字。
* `T`:8B/16B/4H/8H/2S/4S/2D。
* `<Vn>`:第一个源寄存器 SIMD&FP 名字。
* `<Vm>`:第二个源寄存器 SIMD&FP 名字。

示例：

* trn2 v7.2s v5.2s, v7.2s

