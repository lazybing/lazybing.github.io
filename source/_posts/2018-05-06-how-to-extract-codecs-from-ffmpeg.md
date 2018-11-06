---
layout: post
title: "如何从FFMpeg中提取CODEC(以TTA Decoder为例)"
date: 2018-05-06 06:55:35 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

[FFMpeg](https://ffmpeg.org/) 作为音视频领域的开源工具，它几乎可以实现所有针对音视频的处理。最近一直做得工作是从 FFMpeg 中提取特定的编解码器，本位以最简单的 TTA Decoder 为例，介绍如何同 FFMpeg 中提取 CODEC。

<!--more-->

## TTA 简介

TTA(The True Audio Codec) 是免费、简单、实时无损视频压缩。基于 Adaptive Prognostic Filters, TTA 同其他同类的开源项目有强竞争力。

## FFMpeg 中 TTA Decoder

FFMpeg 中关于 TTA Decoder 的部分在`libavcodec/tta.c`中定义: 

```
AVCodec ff_tta_decoder = {
    .name           = "tta",
    .long_name      = NULL_IF_CONFIG_SMALL("TTA (True Audio)"),
    .type           = AVMEDIA_TYPE_AUDIO,
    .id             = AV_CODEC_ID_TTA,
    .priv_data_size = sizeof(TTAContext),
    .init           = tta_decode_init,
    .close          = tta_decode_close,
    .decode         = tta_decode_frame,
    .init_thread_copy = ONLY_IF_THREADS_ENABLED(init_thread_copy),
    .capabilities     = AV_CODEC_CAP_DR1 | AV_CODEC_CAP_FRAME_THREADS,
    .priv_class       = &tta_decoder_class,
};
```

从 TTA AVCodec 的定义可以看出，Decoder 的主要函数只有三个`tta_decode_init`、`tta_decode_frame`、`tta_decode_close`三部分。其中 init 部分主要是解析 TTA Header 信息，decode 部分是真正解码部分，close 主要是释放内存。

不管是硬件解码还是软件解码，Decoder 部分一般都包含六部分：解码器初始化、解码器释放、设置压缩数据给解码器、从解码器获取解码后的数据、设置参数给解码器、从解码器获取参数信息。因此我们可以按照上面的思路，将 FFMpeg 中的这几个函数拆分成相应的函数。

## 提取 TTA Decoder 中可能遇到的问题

## 提取 TTA Decoder 实现
