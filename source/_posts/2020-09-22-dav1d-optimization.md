---
layout: post
title: "AV1(DAV1D)解码详解(八)DAV1D源码优化 dav1d_optimization"
date: 2019-12-22 09:05:50 -0700
comments: true
categories: av1
---

DAV1D 作为 AV1 最高效的解码器，仍然有可优化的空间，根据自己的理解，可执行的优化方案大概从三个方面实现：程序流程、算法实现、编程语言三个角度进行优化。

<!--more-->

# 程序流程

# 算法实现

Film Grain 部分，利用局部性原理。

# 编程语言

NEON 优化：LoopFilter、CDEF Filter、LoopRestoration Filter、MC。
