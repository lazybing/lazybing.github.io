---
layout: post
title: "FFMPEG 源码分析：avcodec_register_all"
date: 2016-12-05 08:42:17 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

avcodec_register_all 提供注册`codec``parsers``filters`的功能。

<!--more-->

## avcodec_register_all 框架
{% codeblock lang:c avcodec_register_all %}
void avcodec_register_all(void)
{
    static int initialized;

    if(initialized)
        return;
    initialized = 1;

    /* hardwar accelerators */
    REGISTER_HWACCEL(H264_MMAL,h264_mmal);
    ......

    /* video codecs */
    REGISTER_DECODER(HEVC,hevc);
    ......
    REGISTER_ENCDEC (MPEG4,mpeg4);
    ......
    /* audio codecs */
    REGISTER_ENCDEC (AAC,aac);
    ......
    /* parsers */
    REGISTER_PARSER(HEVC,hevc);
    /* bitstream filters */
    REGISTER_BSF(HEVC_MP4TOANNEXB,hevc_mp4toannexb);
}
{% endcodeblock %}
## 调用关系
<img src="/images/avcodec_register_all/avcodec_register_all.png">

## 源码分析

