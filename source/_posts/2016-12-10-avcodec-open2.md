---
layout: post
title: "FFMPEG 源码分析：avcodec_open2"
date: 2016-12-10 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

`avcodec_open2`函数实现的功能为利用给定的`AVCodec`结构初始化`AVCodecContext`结构。  

<!--more-->

## 函数声明

`avcodec_open2`的声明如下:  

```
int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, AVDictionary **options);
```

函数参数说明：  

* avctx:需要初始化的context.
* codec:
* options:
* 返回值：如果返回0，正确。失败则返回负数。  

该函数利用给定的`AVCodec`结构初始化`AVCodecContext`结构，在使用该函数之前，`AVCodecContext`
必须已经用`avcodec_alloc_context3()`函数分配出来。  

`AVCodec`结构在使用该函数之前，由`avcodec_find_decoder_by_name``avcodec_find_encoder_by_name`
`avcodec_find_decoder`或`avcodec_find_encoder`提前得到。  

注意，在正式解码之前(比如使用`avcodec_decode_video2()`之前)，必须调用`avcodec_open2`函数。  

## 函数使用示例

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

## 函数源码分析

`avcodec_open2`的逻辑非常简单，首先是进行一些参数检测、之后调动`AVCodec`的init函数。大概步骤如下：  

* 各种函数参数检测。
* 各种结构体分配内存。
* 将输入的`AVDictionary`形式的选项设置到`AVCodecContext`。
* 其他一些零散的查，检查输入参数是否符合编码器的要求。
* 调用`AVCodec`的init函数初始化具体的解码器。  

此处重点分析调用`AVCodec`的init函数处。 以 HEVC 解码器为例。  

{% codeblock lang:c %}
AVCodec ff_hevc_decoder = {
    .name                  = "hevc",
    .long_name             = NULL_IF_CONFIG_SMALL("HEVC (High Efficiency Video Coding)"),
    .type                  = AVMEDIA_TYPE_VIDEO,
    .id                    = AV_CODEC_ID_HEVC,
    .priv_data_size        = sizeof(HEVCContext),
    .priv_class            = &hevc_decoder_class,
    .init                  = hevc_decode_init,
    .close                 = hevc_decode_free,
    .decode                = hevc_decode_frame,
    .flush                 = hevc_decode_flush,
    .update_thread_context = hevc_update_thread_context,
    .init_thread_copy      = hevc_init_thread_copy,
    .capabilities          = AV_CODEC_CAP_DR1 | AV_CODEC_CAP_DELAY |
                             AV_CODEC_CAP_SLICE_THREADS | AV_CODEC_CAP_FRAME_THREADS,
    .profiles              = NULL_IF_CONFIG_SMALL(profiles),
};
{% endcodeblock %}

其中 init 函数定义如下：  

{% codeblock lang:c %}
static av_cold int hevc_decode_init(AVCodecContext *avctx)
{
    HEVCContext *s = avctx->priv_data;
    int ret;

    ff_init_cabac_states();

    avctx->internal->allocate_progress = 1;

    ret = hevc_init_context(avctx);
    if (ret < 0)
        return ret;

    s->enable_parallel_tiles = 0;
    s->picture_struct = 0;

    if(avctx->active_thread_type & FF_THREAD_SLICE)
        s->threads_number = avctx->thread_count;
    else
        s->threads_number = 1;

    if (avctx->extradata_size > 0 && avctx->extradata) {
        ret = hevc_decode_extradata(s);
        if (ret < 0) {
            hevc_decode_free(avctx);
            return ret;
        }
    }

    if((avctx->active_thread_type & FF_THREAD_FRAME) && avctx->thread_count > 1)
            s->threads_type = FF_THREAD_FRAME;
        else
            s->threads_type = FF_THREAD_SLICE;

    return 0;
}
{% endcodeblock %}


