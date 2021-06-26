---
layout: post
title: "AV1(DAV1D)解码详解(七)之帧间编码 Inter Predicton"
date: 2019-11-20 08:04:43 -0800
comments: true
categories:  av1
---

* list element with functor item
{:toc}

Motion Compensation 在视频编解码中是非常重要的模块。(未完待续)

<!--more-->

## OBMC 概述

OBMC 会使用当前块运动矢量和相邻子块运动矢量进行运动补偿，减少方块效应。OBMC 通过融合相邻块的 Motion Vector 预测，很大程度上降低当前块预测错误。

本文通过学习文献`Variable Block-Size Overlapped Block Motion Compensation In The Next Generation Open-Source Video Codec`学习 OBMC 算法在 AV1 中的应用，并对应到 DAV1D 源码中的应用。

OBMC 会使用当前块运动矢量和相邻子块运动矢量进行运动补偿，减少方块效应。OBMC 通过融合相邻块的 Motion Vector 预测，很大程度上降低当前块预测错误。

运动补偿技术通过高效的降低时间冗余，对现代视频压缩工具的成功，有非常大的贡献。主流的视频编解码标准中（AV1/VP9/HEVC/H264），它主要是基于块匹配上。

## Warped Motion 概述

Warped motion 模型在 AV1 中是通过两个仿射预测模型完成的，全局和局部的 warped 运动补偿。在真实世界中，物体除了简单的平移运动外，还有淡入、淡出、旋转、视角运动、不规则运动等，对于这种运动，使用放射预测能很好地提高编码性能。  



