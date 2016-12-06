---
layout: post
title: "FFMPEG 源码分析：avcodec_find_decoder和avcodec_find_encoder"
date: 2016-12-06 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}
`avcodec_find_decoder`和`avcodec_find_encoder` 主要是查找 FFmpeg 的解码器和编码器。  
<!--more-->

avcodec_find_decoder 和 avcodec_find_encoder 主要是利用 AVCodecID 来查找编解码器。  
其实质是遍历AVCodec 链表并且获得符合AVCodecID的元素。  

avcodec_find_decoder 定义如下：  

{% codeblock [lang:c] avcodec_find_decoder %}
AVCodec *avcodec_find_decoder(enum AVCodecID id)
{
    return find_encdec(id, 0);
}
{% endcodeblock %}

由定义可以看出，该函数利用 AVCodecID 查找 AVCodec，并将找到的 AVCodec 返回。
`find_encdec`定义如下：  
{% codeblock [lang:c] find_encdec %}
static AVCodec *find_encdec(enum AVCodecID id, int encoder)
{
    AVCodec *p, *experimental = NULL;
    p = first_avcodec;
    id= remap_deprecated_codec_id(id);
    while (p) {
        if ((encoder ? av_codec_is_encoder(p) : av_codec_is_decoder(p)) &&
            p->id == id) {
            if (p->capabilities & AV_CODEC_CAP_EXPERIMENTAL && !experimental) {
                experimental = p;
            } else
                return p;
        }
        p = p->next;
    }
    return experimental;
}
{% endcodeblock %}

其中`av_codec_is_decoder`定义如下：  
{% codeblock [lang:c] av_codec_is_decoder %}
int av_codec_is_decoder(const AVCodec *codec)
{
    return codec && codec->decode;
}
{% endcodeblock %}

`av_codec_is_encoder`定义如下：  
{% codeblock [lang:c] av_codec_is_decoder %}
int av_codec_is_encoder(const AVCodec *codec)
{
    return codec && (codec->encode_sub || codec->encode2);
}
{% endcodeblock %}

查找编解码器除了上述的`avcodec_find_decoder`和`avcodec_find_encoder`外，还可以利用编解码器名字来查找函数为：avcodec_find_encoder_by_name 和 avcodec_find_decoder_by_name，在此不再赘述。




