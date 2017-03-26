---
layout: post
title: "AVCodec 结构体解析"
date: 2016-07-03 01:11:57 -0700
comments: true
categories: FFMPEG源码分析
---
AVCodec是存储编解码器信息的结构体。
<!--more-->

{% codeblock lang:c %}
typedef struct AVCodec{
    
	const char *name;
    const char *long_name;
    enum AVMediaType type;
    enum AVCodecID id;
    int capabilities;
    const AVRational *supported_framerates; ///< array of supported framerates, or NULL if any, array is terminated by {0,0}
    const enum AVPixelFormat *pix_fmts;     ///< array of supported pixel formats, or NULL if unknown, array is terminated by -1
    const int *supported_samplerates;       ///< array of supported audio samplerates, or NULL if unknown, array is terminated by 0
    const enum AVSampleFormat *sample_fmts; ///< array of supported sample formats, or NULL if unknown, array is terminated by -1
    const uint64_t *channel_layouts;         ///< array of support channel layouts, or NULL if unknown. array is terminated by 0
    uint8_t max_lowres;                     ///< maximum value for lowres supported by the decoder, no direct access, use av_codec_get_max_lowres()
    const AVClass *priv_class;              ///< AVClass for the private context
    const AVProfile *profiles;              ///< array of recognized profiles, or NULL if unknown, array is terminated by {FF_PROFILE_UNKNOWN}
    int priv_data_size;
    struct AVCodec *next;
    int (*init_thread_copy)(AVCodecContext *);
    int (*update_thread_context)(AVCodecContext *dst, const AVCodecContext *src);
    const AVCodecDefault *defaults;
    void (*init_static_data)(struct AVCodec *codec);

    int (*init)(AVCodecContext *);
    int (*encode_sub)(AVCodecContext *, uint8_t *buf, int buf_size,
    int (*encode2)(AVCodecContext *avctx, AVPacket *avpkt, const AVFrame *frame,
                   int *got_packet_ptr);
    int (*decode)(AVCodecContext *, void *outdata, int *outdata_size, AVPacket *avpkt);
    int (*close)(AVCodecContext *);
    void (*flush)(AVCodecContext *);
    int caps_internal;
	
}
{% endcodeblock %}

其中的`name`和`long_name`分别是简短和详细的描述了具体的 codec。而
`type`是指媒体类型，如`AVMEDIA_TYPE_VIDEO``AVMEDIA_TYPE_AUDIO`等。`id`是指具体的 codec 类型，
比如`AV_CODEC_ID_HEVC`。`supported_framerates`是指视频的帧率。`pix_fmts`是指视频图像对应的格式，比如`AV_PIX_FMT_YUV420P``AV_PIX_FMT_RGB24`等。
·

以 HEVC 为例。

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

关于 AVCodec 的注册使用函数`avcodec_register_all`,该函数会调用`REGISTER_DECODER(HEVC, hevc);`, 其中的`REGISTER_DECODER`定义如下：
{% codeblock lang:c %}
#define REGISTER_DECODER(X, x)                                          \
    {                                                                   \
        extern AVCodec ff_##x##_decoder;                                \
        if (CONFIG_##X##_DECODER)                                       \
            avcodec_register(&ff_##x##_decoder);                        \
    }
{% endcodeblock %}

其中的`avcodec_register`定义如下：

{% codeblock lang:c %}
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


下面简单介绍一下遍历ffmpeg中的解码器信息的方法（这些解码器以一个链表的形式存储）：

1. 注册所有编解码器：av_register_all();
2. 声明一个AVCodec类型的指针，比如说AVCodec* first_c;
3. 调用av_codec_next()函数，即可获得指向链表下一个解码器的指针，循环往复可以获得所有解码器的信息。注意，如果想要获得指向第一个解码器的指针，则需要将该函数的参数设置为NULL。

