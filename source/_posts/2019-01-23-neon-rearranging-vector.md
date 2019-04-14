---
layout: post
title: "NEON 编程5——重排矢量"
date: 2019-01-23 07:35:06 -0700
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

本文描述了用于重置矢量寄存器数据的NEON指令。

<!--more-->

## 介绍

当写 NEON 代码时，你或许会发现某些时候，寄存器中的数据格式并不适用于你的算法。可能需要重排矢量中的元素，从而让后续的算术可以。

重新排序操作称为**permutation**，**permutation**指令重置单独像素、选择从单个或多个寄存器来组织一个新的矢量。

## 开始之前

在使用 NEON 提供的**permutation**指令之前，一定要想清楚是否真的需要使用它们。**permutation**指令与 move 指令相似，因为它们通常代表用于准备数据而不是处理数据的 CPU 周期。  

## 可替换的

如何避免不必要的*permutes*？有如下方法选项：  

* **重排输入数据**.

* **重新设计算法**

* **修改上一个处理阶段**

* **使用交错负载和存储**  

* **综合方法**

## 指令

### VMOV 和 VSWAP：Move 和 Swap

### VREV:Reverse

### VEXT:Extract

### VRTN:Transpose

### VZIP 和 VUZP:Zip 和 Unzip

### VTBL, VTBX:Table 和 Table Extend

### 其他

## 结论

仔细考虑你的代码是否真的需要重置你的数据是明智的。然而，当你的算法需要它时，permute 指令提供了一个高效的方法来使得你的数据存放到正确的格式。 


