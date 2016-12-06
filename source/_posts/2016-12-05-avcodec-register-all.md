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

从`avcodec_register_all`的框架和调用关系图可以看出，该函数主要注册硬件加速器、codec、parsers、比特流过滤器等。

## 源码分析

### 注册一次

{% codeblock lang:c initialized_once %}
static int initialized;

if(initialized)
    return;
initialized = 1;
{% endcodeblock %}

该段代码可以看出，当调用过该函数一次后，再次调用时，该函数直接返回。  
注意，这种方法在 FFMEPG 源码中非常常见。  

### 注册硬件加速器

{% codeblock lang:c REGISTER_HWACCEL %}
#define REGISTER_HWACCEL(X, x)                                          \
    {                                                                   \
        extern AVHWAccel ff_##x##_hwaccel;                              \
        if (CONFIG_##X##_HWACCEL)                                       \
            av_register_hwaccel(&ff_##x##_hwaccel);                     \
    }
{% endcodeblock %}

以`H264`为例，`REGISTER_HWACCEL(H264_MMAL, h264_mmal)`展开如下：

```
extern AVHWAccel ff_h264_mmal_hwaccel;
if(CONFIG_H264_MMAL_HWACCEL)
    av_register_hwaccel(&ff_h264_mmal_hwaccel);
```

`av_register_hwaccel(&ff_h264_mmal_hwaccel)` 展开如下：

{% codeblock lang:c REGISTER_HWACCEL %}
void av_register_hwaccel(AVHWAccel *hwaccel)
{
    AVHWAccel **p = last_hwaccel;
    hwaccel->next = NULL;
    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, hwaccel))
        p = &(*p)->next;
    last_hwaccel = &hwaccel->next;
}
{% endcodeblock %}

### 注册codec  

### 注册parser  

### 注册bitstream filters 





