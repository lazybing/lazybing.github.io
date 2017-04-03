---
layout: post
title: "FFMPEG 源码分析：avcodec_open2"
date: 2016-12-10 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

`avcodec_open2`函数实现的功能为利用给定的`AVCodec`结构初始化`AVCodecContext`结构。  

<!--more-->

`avcodec_open2`的声明如下:  

```
int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, AVDictionary **options);
```

该函数利用给定的`AVCodec`结构初始化`AVCodecContext`结构，在使用该函数之前，`AVCodecContext`
必须已经用`avcodec_alloc_context3()`函数分配出来。  

`AVCodec`结构在使用该函数之前，由`avcodec_find_decoder_by_name``avcodec_find_encoder_by_name`
`avcodec_find_decoder`或`avcodec_find_encoder`提前得到。  

注意，在正式解码之前(比如使用`avcodec_decode_video2()`之前)，必须调用`avcodec_open2`函数。  

示例代码如下：

{% codeblock lang:c %}
avcodec_register_all();
av_dict_set(&opt, "b", "2.5M", 0);
codec = avcodec_find_decoder(AV_CODEC_ID_H264);
if(!codec)
    exit(1);

context = avcodec_alloc_context3(codec);

if(avcodec_open2(context, codec, opts) < 0)
    exit(1);
{% endcodeblock %}

函数参数说明：  

* avctx:需要初始化的context.
* codec:
* options:
* 返回值：如果返回0，正确。失败则返回负数。  





