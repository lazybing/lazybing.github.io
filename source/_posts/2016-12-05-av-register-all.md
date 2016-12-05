---
layout: post
title: "FFMEPG 源码分析：av_register_all"
date: 2016-12-05 04:45:48 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}
 
`av_register_all()`几乎是所有使用 FFMPEG 编程调用的第一个函数。`av_register_all()`的主要功能是注册所有的 formats 和 protocols。

<!--more-->

## av_register_all 框架  

首先列一下该函数的大体框架：  
{% codeblock lang:c av_register_all %}
void av_register_all(void)
{
    static int initialized;

    if(initialized)
        return;
    initialized = 1;

    avcodec_register_all();

    /*(de)muxers*/
    ......
    REGISTER_MUXER   (F4V,              f4v);
    ......
    REGISTER_MUXDEMUX(FLV,              flv);
    REGISTER_MUXDEMUX(H264,             h264);
    REGISTER_MUXDEMUX(HEVC,             hevc);
    REGISTER_MUXER   (MP4,              mp4);

    /*protocols*/
    REGISTER_PROTOCOL(RTMP,             rtmp);
    REGISTER_PROTOCOL(TCP,              tcp);
    REGISTER_PROTOCOL(UDP,              udp);
    ......
}
{% endcodeblock %}

## 调用关系  
<img src="/images/av_register_all/av_register_all.png">

从调用关系图可以看出，通过调用[avcodec_register_all](http://lazybing.github.io/blog/2016/12/05/avcodec-register-all/)注册了和编解码器有关的组件；硬件加速器、解码器、编码器、Parser、Bistream Filter等，以及复用器、解复用器、协议处理。  

## 源码分析

### 注册一次  

{% codeblock lang:c initialized_once %}
static int initialized;

if (initialized)
    return;
initialized = 1;
{% endcodeblock %}

该段代码可以看出，当调用过该函数一次后，再次调用时，该函数直接返回。  
注意，这种方法在 FFMEPG 源码中非常常见。

### 注册 codec 

```
avcodec_register_all();
```
该函数的作用为注册`codecs``parsers`和`filters`。  
该函数的源码，还请访问[avcodec_register_all](http://lazybing.github.io/blog/2016/12/05/avcodec-register-all/)函数。  

### 注册复用器

{% codeblock lang:c REGISTER_MUXER %}
#define REGISTER_MUXER(X, x)                                            \
    {                                                                   \
        extern AVOutputFormat ff_##x##_muxer;                           \
        if (CONFIG_##X##_MUXER)                                         \
            av_register_output_format(&ff_##x##_muxer);                 \
    }
{% endcodeblock %}

以`MP4`为例，`REGISTER_MUXER(MP4, mp4)`展开如下：  
```
extern AVOutpusFormat ff_mp4_muxer;
if(CONFIG_MP4_MUXER)
    av_register_output_format(&ff_mp4_muxer);
```

`av_register_output_format(&ff_mp4_muxer)`展开如下：  

{% codeblock lang:c av_register_output_format %}
void av_register_output_format(AVOutputFormat *format)
{
    AVOutputFormat **p = last_oformat;

    format->next = NULL;
    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, format))
        p = &(*p)->next;
    last_oformat = &format->next;
}
{% endcodeblock %}

### 注册解复用器 

{% codeblock lang:c REGISTER_MUXER %}
#define REGISTER_DEMUXER(X, x)                                          \
    {                                                                   \
        extern AVInputFormat ff_##x##_demuxer;                          \
        if (CONFIG_##X##_DEMUXER)                                       \
            av_register_input_format(&ff_##x##_demuxer);                \
    }
{% endcodeblock %}

`av_register_input_format(&ff_mp4_muxer)`展开如下：  

{% codeblock lang:c av_register_output_format %}
void av_register_input_format(AVInputFormat *format)
{
    AVInputFormat **p = last_iformat;

    format->next = NULL;
    while(*p || avpriv_atomic_ptr_cas((void * volatile *)p, NULL, format))
        p = &(*p)->next;
    last_iformat = &format->next;
}
{% endcodeblock %}

{% codeblock lang:c avpriv_atomic_ptr_cas %}
void *avpriv_atomic_ptr_cas(void * volatile *ptr, void *oldval, void *newval)
{
    void *ret;
    pthread_mutex_lock(&atomic_lock);
    ret = *ptr;
    if (ret == oldval)
        *ptr = newval;
    pthread_mutex_unlock(&atomic_lock);
    return ret;
}
{% endcodeblock %}

{% codeblock lang:c REGISTER_MUXDEMUX %}
#define REGISTER_MUXDEMUX(X, x) REGISTER_MUXER(X, x); REGISTER_DEMUXER(X, x)
{% endcodeblock %}

### 注册协议

{% codeblock lang:c REGISTER_PROTOCOL %}
#define REGISTER_PROTOCOL(X, x)                                         \
    {                                                                   \
        extern URLProtocol ff_##x##_protocol;                           \
        if (CONFIG_##X##_PROTOCOL)                                      \
            ffurl_register_protocol(&ff_##x##_protocol);                \
    }
{% endcodeblock %}

以`TCP`为例，`REGISTER_PROTOCOL(TCP,tcp)`展开如下：  

```
extern URLProtocol ff_tcp_protocol;
if(CONFIG_TCP_PROTOCOL)
    ffurl_register_protocol(&ff_tcp_protocol);
```

`ffurl_register_protocol(&ff_tcp_protocol)`展开如下：  

{% codeblock lang:c ffurl_register_protocol %}
int ffurl_register_protocol(URLProtocol *protocol)
{
    URLProtocol **p;
    p = &first_protocol;
    while (*p)
        p = &(*p)->next;
    *p             = protocol;
    protocol->next = NULL;
    return 0;
}
{% endcodeblock %}

