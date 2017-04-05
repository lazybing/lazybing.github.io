---
layout: post
title: "FFMPEG 源码分析：avcodec_decode_video2"
date: 2016-12-20 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

`avcodec_decode_video`函数的作用是解码`AVPacket`中的压缩数据，解码为图像数据。
某些解码器支持在一个`AVPacket`中包含多帧，这类的解码器只解码第一帧。  

<!--more-->

## 函数声明

```
int avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr,
                         const AVPacket *avpkt);
```

注意，输入内存的对齐字节(AV_INPUT_BUFFER_PADDING_SIZE)比实际读取字节要大，因为某些
最优流可能会读取 32 或 64 bits 每次。  

在将压缩数据packets给到解码器之前，`AVCodecContext`必须用`avcodec_open2`设置过。  

函数参数：  

* `AVCodecContext *`。  
* `AVFrame *`存放解码的视频数据，它使用`av_frame_alloc`获得一个`AVFrame`。解码器会调用
`AVCodecContext.get_buffer2`回调函数为实际的位图分配内存。  
* `got_picture_ptr`,如果没有帧可以解码，该值被设为0。否则，它是非零值。  
* `AVPacket *`包含输入缓存。该结构体使用`av_init_packet`创建后会设置`data`和`size`，某些
解码器可能需要更多的字段,如`flags & AV_PKT_FLAG_KEY`。解码器被设置为使用最少的字段。  

返回值：如果解码出错，返回负值；否则返回使用的字节数。  

## 源码分析

`avcodec_decode_video2`函数比较简单，主要做了以下几个工作：  

1. 对输入的字段进行一些列的检查工作，比如宽高是否正确，输入是否为视频等等。  
2. 真正的解码，通过`avctx->codec->decode`实现，它会调用相应的`AVCodec`的 decode 函数，完成解码。  
3. 对得到的`AVFrame`进行一些字段进行赋值，例如宽高、像素格式等等。  

{% codeblock lang:c avcodec_decode_video2 %}
int attribute_align_arg avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                                              int *got_picture_ptr,
                                              const AVPacket *avpkt)
{
    ...
    //检测输入参数
    if (!avctx->codec)
        return AVERROR(EINVAL);
    if (avctx->codec->type != AVMEDIA_TYPE_VIDEO) {
        av_log(avctx, AV_LOG_ERROR, "Invalid media type for video\n");
        return AVERROR(EINVAL);
    }

    *got_picture_ptr = 0;
    if ((avctx->coded_width || avctx->coded_height) && av_image_check_size(avctx->coded_width, avctx->coded_height, 0, avctx))
        return AVERROR(EINVAL);

    ...
    //真正的解码
    ret = avctx->codec->decode(avctx, picture, got_picture_ptr,
            &tmp);

    ...
    //设置参数
    if (!(avctx->codec->capabilities & AV_CODEC_CAP_DR1)) {
        if (!picture->sample_aspect_ratio.num)    picture->sample_aspect_ratio = avctx->sample_aspect_ratio;
            if (!picture->width)                      picture->width               = avctx->width;
            if (!picture->height)                     picture->height              = avctx->height;
            if (picture->format == AV_PIX_FMT_NONE)   picture->format              = avctx->pix_fmt;
    }
    ...
}
{% endcodeblock %}

以H.265解码器为例，解码示例如下：  

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
    ...
};
{% endcodeblock %}

其中`hevc_decode_frame`是解码器的真正的解码函数，定义如下：  
{% codeblock lang:c hevc_decode_frame %}
static int hevc_decode_frame(AVCodecContext *avctx, void *data, int *got_output,
                             AVPacket *avpkt)
{
    int ret;
    HEVCContext *s = avctx->priv_data;

    if (!avpkt->size) {
        ret = ff_hevc_output_frame(s, data, 1);
        if (ret < 0)
            return ret;

        *got_output = ret;
        return 0;
    }

    s->ref = NULL;
    ret    = decode_nal_units(s, avpkt->data, avpkt->size);
    if (ret < 0)
        return ret;

    if (avctx->hwaccel) {
        if (s->ref && (ret = avctx->hwaccel->end_frame(avctx)) < 0) {
            av_log(avctx, AV_LOG_ERROR,
                   "hardware accelerator failed to decode picture\n");
            ff_hevc_unref_frame(s, s->ref, ~0);
            return ret;
        }
    } else {
        /* verify the SEI checksum */
        if (avctx->err_recognition & AV_EF_CRCCHECK && s->is_decoded &&
            s->is_md5) {
            ret = verify_md5(s, s->ref->frame);
            if (ret < 0 && avctx->err_recognition & AV_EF_EXPLODE) {
                ff_hevc_unref_frame(s, s->ref, ~0);
                return ret;
            }
        }
    }
    s->is_md5 = 0;

    if (s->is_decoded) {
        av_log(avctx, AV_LOG_DEBUG, "Decoded frame with POC %d.\n", s->poc);
        s->is_decoded = 0;
    }

    if (s->output_frame->buf[0]) {
        av_frame_move_ref(data, s->output_frame);
        *got_output = 1;
    }

    return avpkt->size;
}
{% endcodeblock %}

