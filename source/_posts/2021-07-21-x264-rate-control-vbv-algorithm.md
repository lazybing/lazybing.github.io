---
layout: post
title: "x264码率控制之VBV详解"
date: 2021-07-21 05:43:06 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

VBV 作为 H264 中码率控制的重要模块，它的作用是确保码率不会超过某个最大值。

<!--more-->

先来看一下，VBV 的作用，如图所示。分别设置`vbv-maxrate 2000`/`vbv-maxrate 1500`/`vbv-bufsize 2000`/`vbv-bufsize 1500`。

{% img /images/h264_vbv/ratecontrol_vbv.PNG 'VBV' %}

## 为什么需要 VBV Buffer

假设我们的编码是面向存储的，那么就无需这个 buffer，编码出来的码率随便你怎么波动，我只存在本地就 OK。现在问题是我们是面向传输的，要考虑到网络的带宽问题，以及网络的抖动，如果我们编码出来的码率变化非常大，那么很不利于传输，比如为了帧的质量，突然编出来一个很大的帧，需要传输很久，那么解码端就会需要等很久，体现在播放时上是长时间卡住。因此需要这个 buffer 来平滑码率，它通过码率控制模块来进行反馈，当码率控制模块检测 buffer 时发现 buffer 很满了，就通过调节 QP 的方法，使编码的码率降下来。另外关于时延的问题，必须说明的是，引入 vbv buffer 模型并不是为了降低时延，相反它反而会引入时延，但它可以有效防止时延抖动，让你看视频不卡（只要防止下溢就行），通过把初始充盈度调大一点就能做的很好。引自[假想参考解码器 vbv HRD](https://blog.csdn.net/ccc_cccd/article/details/114042493)


