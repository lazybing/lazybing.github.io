---
layout: post
title: "AV1 解码详解(四)之LOOP RESTORATION"
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

Degraded 帧的每个像素都经过维纳滤波，维纳滤波的系数存在码流中。因为归一化和对称性，对于垂直和水平滤波器，只需要从编码端传递三个参数。编码器决定使用的滤波抽头(filter tap),解码端只是简单的使用从码流中获取的滤波抽头。

分析`DAV1D`解码中，维纳滤波主要分为三步：

* 填充数据(padding)，此步骤主要目的是为后面的滤波做准备，将后面用到的像素汇集到一起。因为此步骤并没有改变一些像素的值，只是为了后面的滤波更加方便，所以该步骤在优化时，可以去掉，直接进行滤波，这样就少了一步数据拷贝，可以提升解码效率，在它的 ARM 汇编的实现中，就是这样做的。
* 水平滤波。该步通过水平滤波，将上面的填充数据滤波到另外一个临时数组中，水平滤波后的数据时为下一步的垂直滤波做数据准备的。
* 垂直滤波。该步通过垂直滤波，将水平滤波结束的数据重新放回最初原始数据的位置，从而完成对像素的整个维纳滤波。 

{% img /images/av1_lr/wiener_filter.png %}

## Selfguided Filter 自导向投影滤波器

## 参考文档

1. [AV1 Bitstream and Decoding Process](https://aomediacodec.github.io/av1-spec/av1-spec.pdf)
2. [An Overview of Core Coding Tools in the AV1 Video Codec](https://jmvalin.ca/papers/AV1_tools.pdf)
3. [A SWITCHABLE LOOP-RESTORATION WITH SIDE-INFORMATION FRAMEWORK FOR THE EMERGING AV1 VIDEO CODEC](https://static1.squarespace.com/static/56ac12221f40397fbfd21993/t/59cf3d9a2278e777855714bb/1506753947391/0000265.pdf)  

