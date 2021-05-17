---
layout: post
title: "H264 Motion Estimation Algorithm"
date: 2021-05-17 07:54:51 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

运动估计是寻找运动矢量的过程。在整个编码过程中，运动估计耗时占了整个编码过程的60%-80%不等，因此，对运动估计的优化是实现视频实时应用的关键。

H264 中运动估计的过程分为两步：1. 整数像素精度的估计。2. 分数像素级精度的估计。其中整数像素级的运动估计包括两类算法：全搜索算法、快速搜索算法(DIA/HEX/UMH)。

<!--more-->

## 钻石搜索算法

## 六边形搜索算法

## 非对称交叉多层次六边形网格搜索算法

