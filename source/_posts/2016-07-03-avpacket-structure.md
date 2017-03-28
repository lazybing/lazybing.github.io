---
layout: post
title: "AVPacket 结构体解析"
date: 2016-07-03 08:19:32 -0700
comments: true
categories: FFMPEG源码分析
---

AVPacket是存储压缩编码数据相关信息的结构体。
<!--more-->

`AVPacket`作为 demuxer 的输出，并作为 decoder 的输入；或者作为 encoder 的输出，muxer 的输入。
对于 video,它一般包含一个压缩帧；对于 audio，它可能包含多个压缩音频帧。

{% codeblock lang:c %}

typedef struct AVPacket{

    AVBufferRef *buf;
    int64_t pts;
    int64_t dts;
    uint8_t *data;
    int   size;
    int   stream_index;
    int   flags;
    AVPacketSideData *side_data;
    int side_data_elems;
    int   duration;
    int64_t pos;                            ///< byte position in stream, -1 if unknown
    int64_t convergence_duration;

}

{% endcodeblock %}

* `pts`代表显示时间戳(单位是AVStream->time_base units).  
* `dts`代表解码时间戳(单位是AVStream->time_base units).
* `stream_index`标识该`AVPacket`所属的视频音频流。  

