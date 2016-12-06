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

{% codeblock lang:c av_register_hwaccel %}
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

{% codeblock lang:c REGISTER_DECODER %}
#define REGISTER_DECODER(X, x)                                          \
    {                                                                   \
        extern AVCodec ff_##x##_decoder;                                \
        if (CONFIG_##X##_DECODER)                                       \
            avcodec_register(&ff_##x##_decoder);                        \
    }
{% endcodeblock %}

以`HEVC`为例，`REGISTER_DECODER(HEVC, hevc)`展开如下：  

```
extern AVCodec ff_hevc_decoder;
if(CONFIG_HEVC_DECODER)
    avcodec_register(&ff_hevc_decoder);
```

`avcodec_register(&ff_hevc_decoder)`展开如下：  

{% codeblock lang:c avcodec_register %}
av_cold void avcodec_register(AVCodec *codec)
{
    AVCodec **p;
    avcodec_init();
    p = last_avcodec;
    codec->next = NULL;

    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, codec))
        p = &(*p)->next;
    last_avcodec = &codec->next;

    if (codec->init_static_data)
        codec->init_static_data(codec);
}
{% endcodeblock %}

ff_hevc_decoder 定义如下：

{% codeblock lang:c ff_hevc_decoder %}
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

### 注册parser  

{% codeblock lang:c REGISTER_PARSER %}
#define REGISTER_PARSER(X, x)                                           \
    {                                                                   \
        extern AVCodecParser ff_##x##_parser;                           \
        if (CONFIG_##X##_PARSER)                                        \
            av_register_codec_parser(&ff_##x##_parser);                 \
    }
{% endcodeblock %}

以`HEVC`为例，`REGISTER_PARSER(HEVC, hevc)`展开如下： 

```
extern AVCoderParser ff_hevc_parser;
if(CONFIG_HEVC_PARSER)
    av_register_codec_parser(&ff_hevc_parser);
```

`av_register_codec_parser(&ff_hevc_parser)` 展开如下：  

{% codeblock lang:c av_register_codec_parser %}
void av_register_codec_parser(AVCodecParser *parser)
{
    do {
        parser->next = av_first_parser;
    } while (parser->next != avpriv_atomic_ptr_cas((void * volatile *)&av_first_parser, parser->next, parser));
}
{% endcodeblock %}

ff_hevc_parser 定义如下：  

{% codeblock lang:c ff_hevc_parser %}
AVCodecParser ff_hevc_parser = {
    .codec_ids      = { AV_CODEC_ID_HEVC },
    .priv_data_size = sizeof(HEVCParserContext),
    .parser_parse   = hevc_parse,
    .parser_close   = hevc_parser_close,
    .split          = hevc_split,
};
{% endcodeblock %}

### 注册bitstream filters 

{% codeblock lang:c REGISTER_BSF %}
#define REGISTER_BSF(X, x)                                              \
    {                                                                   \
        extern AVBitStreamFilter ff_##x##_bsf;                          \
        if (CONFIG_##X##_BSF)                                           \
            av_register_bitstream_filter(&ff_##x##_bsf);                \
    }
{% endcodeblock %}

以`HEVC`为例，`REGISTER_BSF(HEVC_MP4TOANNEXB, hevc_mp4toannexb)` 展开如下：  

```
extern AVBitStreamFilter ff_hevc_mp4toannexb_bsf;
if(CONFIG_HEVC_MP4TOANNEXB_BSF)
    av_register_bitstream_filter(&ff_hevc_mp4toannexb_bsf);
```

`av_register_bitstream_filter(&&ff_hevc_mp4toannexb_bsf)` 展开如下：  

{% codeblock lang:c av_register_bitstream_filter %}
void av_register_bitstream_filter(AVBitStreamFilter *bsf)
{
    do {
        bsf->next = first_bitstream_filter;
    } while(bsf->next != avpriv_atomic_ptr_cas((void * volatile *)&first_bitstream_filter, bsf->next, bsf));
}
{% endcodeblock %}

ff_hevc_mp4toannexb_bsf 定义如下：  

{% codeblock lang:c ff_hevc_mp4toannexb_bsf %}
AVBitStreamFilter ff_hevc_mp4toannexb_bsf = {
    "hevc_mp4toannexb",
    sizeof(HEVCBSFContext),
    hevc_mp4toannexb_filter,
    hevc_mp4toannexb_close,
};
{% endcodeblock %}


