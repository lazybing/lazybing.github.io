---
layout: post
title: "FFMPEG 源码分析：av_read_frame"
date: 2016-12-15 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

`av_read_frame`函数的作用是返回文件中保存的数据。它会文件中保存的数据分成不同的帧，
每次调用都会返回一帧。注意，该函数不会忽略帧与帧之间无效数据(非帧数据)，目的是给解码器
最多的信息用于解码。

<!--more-->

## 函数声明

```
int av_read_frame(AVFormatContext *s, AVPacket *pkt);
```

如果`pkt->buf`是 NULL,包直到下一次调用`av_read_frame`或`avformat_close_input`时都是有效的。
不需要时，包必须通过`av_free_packet`释放。对于视频，`packet`只包含一帧；对于音频，如果每帧有固定大小(如 PCM 或 ADPCM 数据)，
`packet`可以包含多个音频帧（必须是整数帧）,如果音频帧大小可变(如MPEG 音频)，它只能包含一帧数据。  

`pkt->pts``pkt->dts``pkt->duration`都是以`AVStream.time_base_units`为单位的。
如果视频格式里包含 B 帧，`pkt->pts`可以是`AV_NOPTS_VALUE`,因此如果不解压缩数据，最好
查看`pkt->dts`。  

如果函数返回0，正确；小于0，则为到文件尾或出错。  

## 函数调用关系

<img src="/images/av_read_frame/av_read_frame.png">

## 源码分析

`av_read_frame`函数会判断在未解码缓存中是否有数据，如果有数据则调用`read_from_packet_buffer`。

