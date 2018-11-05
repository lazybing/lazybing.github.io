---
layout: post
title: "av1解码详解(二)之film_grain"
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

`film grain`在去噪音过程中会从视频中去除掉，`grain`参数会通过噪音视频序列和去噪视频序列的差异中获得,这些参数会和压缩视频流一起传输到解码端。 解码后，`film grain`会被叠加到重建视频帧中。  

# Film Grain 流程

从上面的框架图可以看出，`film grain`包括压缩前的去噪、编码参数、解码参数、噪音叠加到重建帧等几个过程，这里不讨论去噪的过程，主要讨论`film grain modeling synthesis`。
流程可以从`SPEC`中看到，也可以从源码中学习，`film grain`中在源码中主要集中在`aom/aom_dsp/grain_synthesis.c`中的`av1_add_film_grain_run`函数中，分析源码可知大致分为如下流程：

* init_array. 为`film grain`准备后面用到的内存，大致分为三类`grain buffer(luma_grain_block/cb_grain_block/cr_grain_block)`、`line buf(y_line_buf/cb_line_buf/cr_line_buf)`、`column buf(y_col_buf/cb_col_buf/cr_col_buf)`。  
* generate_luma_grain_block 和 generate_chroma_grain_blocks. 它会根据码流中 parse 出来的`grain_scale_shift/ar_coeff_lag`的值和`gaussian_sequence`表来填充`grain block`。    
* init_scaling_function. 它是利用码流中 parse 出来的 `scaling_points_y`来填充`scaling_lut_y/scaling_lut_cb/scaling_lut_cr`数组。  
* add_noise_to_block。它会根据上面生成的`grain block`叠加到重建帧上。  


# 参考文档

1. [AV1 Bitstream & Decoding Process](https://aomediacodec.github.io/av1-spec/)

(未完待续...)
