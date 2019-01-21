---
layout: post
title: "NEON 编程3——矩阵相乘"
date: 2019-01-21 06:44:07 -0800
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

前面两篇分别介绍了如何使用 NEON 来加载和存储数据，如何使用 NEON 处理多余的数据。这一篇介绍一点儿使用的数据处理——矩阵相乘。

<!--more-->

## 矩阵

本篇文章会分析如何有效的完成4x4矩阵相乘，这种操作在 3D 图形中经常会用到。假设矩阵存放到内存中，并且是列优先的顺序，该格式在 OpenGL-ES 中使用。

## 语法(Algorithm)

先详细的检测一下矩阵相乘的操作，通过把计算扩展开，并确定哪些子操作可以使用 NEON 指令实现。

{% img /images/neon_matrix_multiply/neon_matrix_multiply.png %}


