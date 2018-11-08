---
layout: post
title: "音频概念介绍(采样频率、帧率、通道数等)"
date: 2018-11-08 07:54:32 -0800
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

最近在给现代汽车做一个从 FFMpeg 中提取各个音频解码器的项目，很多都是音频。因为之前做的大多数都是视频项目，音频知识比较匮乏。限制记录一下。
<!--more-->

## 音频基础概述

首先我们用 MediaInfo 来看下音频流的一些信息如图所示：

{% img /images/audio_basic_concept/audio_basic_concept.png %}

逐个分析：

```
Format:AC-3
Format/Info:Audio Coding 3
Duration:33s 984ms
Bit rate:448 Kbps
Channel(s):6 channels
Channel positions: Front:L C R, Side:L R LFE
Sampling rate:48.0KHz
Bit depth:16bits
Frame rate:31.250 fps 
```

采样率(sampling rate)：声音信号在"模数"转换过程中单位时间内采样的次数。采样率是指每一次采样周期内声音模拟信号的数值，一般的采样率包括：8kHz/11.025kHz/22.05kHz/16kHz/37.8kHz/44.1kHz/48kHz。

帧率(Frame rate):每秒钟中帧数，单位是fps，如上面的 31.250 fps。 

通道数(channels):声音的通道数，常用的有单声道和立体声之分。上面的声道数是 6 通道。

比特率(bit rate):每秒的传输速率(比特率)。

bitspersample:每个 sample 占用的 bits 数。

## PCM 数据摆放格式

在做项目的过程中，经常用到的一点是在输出 PCM 数据时，经常要了解 PCM 的摆放格式。根据不同的 bps 和 channels，数据的摆放时不同的。


{% img /images/audio_basic_concept/pcm_channels_bps.png %}

