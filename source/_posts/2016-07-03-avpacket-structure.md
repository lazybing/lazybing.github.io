---
layout: post
title: "AVPacket 结构体解析"
date: 2016-07-03 08:19:32 -0700
comments: true
categories: FFMPEG源码分析
---

AVPacket是存储压缩编码数据相关信息的结构体。
<!--more-->

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
