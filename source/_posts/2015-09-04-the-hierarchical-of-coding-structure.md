---
layout: post
title: "HM源码分析（一）:HEVC编码结构"
date: 2015-09-04 09:57:17 -0700
comments: true
categories: HM源码分析
---

本文主要记录了 HEVC 的编码时的分层处理架构和编码完成后码流的语法结构两个方面的学习。
<!--more-->

VPS(Video Parameter Set):视频参数集，主要用于传输视频分级信息，包含多个子层和操作点共享的语法元素、会话所需要的有关操作的关键信息（档次/级别等）、其他不属于 SPS 的操作点特性信息（如HRD）。

SPS(Sequence Parameter Set):序列参数集，主要包含一个 CVS 中所有编码图像的共享编码参数。如图像格式信息（采样格式/图像分辨率/量化深度/Crop信息）、编码参数信息（编码块/变换块的尺寸等）、与参考图像相关的信息、可视话可用性信息(VUI)等。

PPS(Picture Parameter Set):图像参数集。

