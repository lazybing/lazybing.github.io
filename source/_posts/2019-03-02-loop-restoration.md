---
layout: post
title: "AV1 解码详解(四)之LOOP RESTORATION(待总结)"
date: 2019-03-02 18:02:55 -0800
comments: true
categories: av1
---

* list element with functor item
{:toc}

LOOP RESTORATION，环内重建滤波器，是一个重要的增强图像质量处理方法。它包含了两种滤波器，编码器会从两者中选择其一。Wiener Filter(维纳滤波器)采用可分离的对称设计。SelfGuided(自导向投影滤波器)使用两个重建信号的线性组合来近似真实信号。编码器通过比较滤波结果，选择合适的参数，并传输给解码器。  

<!--more-->

图像重建是一个比较成熟的领域，它包含了很多专业技术可用，比如 deblocking、deblurring、deringring、debanding、denoising、constrast enhancement、sharpening 和 resolution enhancement。

## Wiener Filter 维纳滤波器

Degraded 帧的每个像素都

## Selfguided Filter 自导向投影滤波器

## 参考文档

1. [AV1 Bitstream and Decoding Process](https://aomediacodec.github.io/av1-spec/av1-spec.pdf)
2. [An Overview of Core Coding Tools in the AV1 Video Codec](https://jmvalin.ca/papers/AV1_tools.pdf)
3. [A SWITCHABLE LOOP-RESTORATION WITH SIDE-INFORMATION FRAMEWORK FOR THE EMERGING AV1 VIDEO CODEC](https://static1.squarespace.com/static/56ac12221f40397fbfd21993/t/59cf3d9a2278e777855714bb/1506753947391/0000265.pdf)  

