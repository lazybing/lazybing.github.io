---
layout: post
title: "FFmpeg 学习之 FFplay源码分析"
date: 2016-11-05 21:03:58 -0700
comments: true
categories: ffmpeg源码分析
---

FFplay 是一个简单便携的媒体播放器，它使用了 FFmpeg 和 SDL 库。  
<!--more-->

首先看一下 FFplay 的使用：安装完 FFmpeg 后，直接在命令行中输入   
```
ffplay [options] bitstream_file
```
其中更详细的使用说明，可以使用`man ffplay`来查看。

其次我们可以通过使用`Esc``q`来推出播放，可以使用空格来暂停播放，可以使用`s`来执行逐帧播放视频等等操作。

ffplay 里面最主要的函数时:`av_register_all()``SDL_Init(flags)``av_init_packet``stream_open``event_loop`。下面逐个分析这几个函数主要完成的功能。  

`av_register_all`实现注册`codecs``demux`和`protocols`。其中注册的`codecs`时通过`avcodec_reigster_all()`函数来实现的；注册`demux`的方法，以 HEVC 为例。

{% codeblock lang:c %}
#define REGISTER_MUXER(X, x)                                            \
    {                                                                   \
        extern AVOutputFormat ff_##x##_muxer;                           \
        if (CONFIG_##X##_MUXER)                                         \
            av_register_output_format(&ff_##x##_muxer);                 \
    }

#define REGISTER_DEMUXER(X, x)                                          \
    {                                                                   \
        extern AVInputFormat ff_##x##_demuxer;                          \
        if (CONFIG_##X##_DEMUXER)                                       \
            av_register_input_format(&ff_##x##_demuxer);                \
    }

#define REGISTER_MUXDEMUX(X, x) REGISTER_MUXER(X, x); REGISTER_DEMUXER(X, x)

REGISTER_MUXDEMUX(HEVC,hevc);
{% endcodeblock %}

将上面的宏展开即为：

{% codeblock lang:c %}
void av_register_input_format(AVInputFormat *format)
{
    AVInputFormat **p = last_iformat;

    format->next = NULL;
    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, format))
        p = &(*p)->next;
    last_iformat = &format->next;
}

void av_register_output_format(AVOutputFormat *format)
{
    AVOutputFormat **p = last_oformat;

    format->next = NULL;
    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, format))
        p = &(*p)->next;
    last_oformat = &format->next;
}
{% endcodeblock %}

{% codeblock lang:c %}
AVOutputFormat ff_hevc_muxer = {
    .name              = "hevc",
    .long_name         = NULL_IF_CONFIG_SMALL("raw HEVC video"),
    .extensions        = "hevc",
    .audio_codec       = AV_CODEC_ID_NONE,
    .video_codec       = AV_CODEC_ID_HEVC,
    .write_packet      = ff_raw_write_packet,
    .flags             = AVFMT_NOTIMESTAMPS,
};
{% endcodeblock %}

