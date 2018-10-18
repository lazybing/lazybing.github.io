---
layout: post
title: "av1解码详解之film_grain(三)"
date: 2018-10-17 08:35:36 -0700
comments: true
categories: av1
---

* list element with functor item
{:toc}

`Film Grain`在电视和电影内容中广泛存在，它经常是创作内容的一部分，在编码过程中需要保留下来，因为`film grain`的随机性，导致很难用传统的压缩算法进行压缩。

<!--more-->

# Film Grain 简介

`film grain`模型和整体框架如图所示。

{% img /images/film_grain_av1/film_grain_framework.png %}

`film grain`在去噪音过程中会从视频中去除掉，`grain`参数会通过噪音视频序列和去噪视频序列的差异中获得,这些参数会和压缩视频流一起传输到解码端。 解码后，`film grain`会被加到重建视频帧中。


# 参考文档

1. [AV1 Bitstream & Decoding Process](https://aomediacodec.github.io/av1-spec/)

(未完待续...)
