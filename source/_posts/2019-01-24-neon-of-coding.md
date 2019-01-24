---
layout: post
title: "ARM 汇编指令总结"
date: 2019-01-24 06:35:54 -0800
comments: true
categories: 汇编学习
---

学习汇编真的太痛苦了。。。一个命令一个命令的学习记录吧

<!--more-->


## SQDMULH(vector)

Signed saturating Doubling Multiply return High half.该指令会将两个源寄存器中对应的元素相乘，将结果加倍，并把结果的高半部分放到矢量中，最后把矢量放到目的寄存器 SIMD&FP 中。

Scalar:

`SQDMULH <V><d>, <V><n>, <V><m>`

Vector:

`SQDMULH <Vd>.<T>, <Vn>.<T>, <Vm>.<T>`

`<Vd>`:目的寄存器 SIMD&FP, `<Vn>`:第一个源寄存器 SIMD&FP, `<Vm>`:第二个源寄存器 SIMD&FP. `<T>`:4H/8H/2S/4S 中的一个。示例

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



