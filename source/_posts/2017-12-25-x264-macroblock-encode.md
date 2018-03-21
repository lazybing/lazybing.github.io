---
layout: post
title: "X264 源码解析之x264_macroblock_encode函数"
date: 2017-12-25 19:52:38 -0800
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文主要记录 X264 中对于`x264_macroblock_encode`函数的分析，该函数主要变换和量化，对应 X264 中的宏块编码模块。  
<!--more-->

## x264_macroblock_encode 概述

该函数主要在`x264_slice_write()`函数调用，它主要完成了编码器中的变换、量化部分，该函数主要是封装了`x264_macroblock_encode_internal()`函数，它包括如下几个步骤：  

{% codeblock lang:c x264_macroblock_encode %}
void x264_macroblock_encode(x264_t *h)
{
    if(CHROMA444)
        x264_macroblock_encode_internal(h, 3, 0);
    else
        x264_macroblock_encode_internal(h, 1, 1);
}
{% endcodeblock %}

1. 如果宏块类型为 PCM 类型，直接存储重建帧数据。  
2. 如果宏块类型为 Skip 类型，调用`x264_macroblock_encode_skip()`编码 Skip 类型宏块，包括`P_SKIP`和`B_SKIP`类型。  
3. 如果宏块类型为`I_16x16`，调用`x264_mb_encode_i16x16()`编码 Intra 16x16 类型的宏块，该函数除了进行 DCT 变换之外，还对 16 个小块的 DC 系数进行 Hadamard 变换。  
4. 如果宏块类型为`I_4x4`，调用`x264_mb_encode_i4x4()`编码 Intra 4x4 类型的宏块。  
5. 帧间宏块编码，该部分并没有单独的函数完成，而是写在了`x264_macroblock_encode_internal`函数内部。  
6. 调用`x264_mb_encode_chroma()`函数编码色度卡。  

### I_PCM 编码模式  

I_PCM 是一种帧内编码模式，在该模式下，编码器直接传输图像的像素值，而不经过预测和变换。在一些特殊的情况下，特别是图像
内容不规则或者量化参数非常低时，该模式比常规的操作（帧内预测-变换-量化-编码）效率更高。  

I_PCM 模式用于以下目的：  

1. 允许编码器精确地表示像素值。  
2. 提供表示不规则图像内容的准确性，而不引起重大的数据量增加。  
3. 严格限制宏块解码比特数，但不降低编码效率。  

对 I_PCM 类型的编码，实现代码如下：  

{% codeblock lang:c %}
...
if(h->mb.i_type == I_PCM)
{
    //if PCM is chosen, we need to store reconstructed frame data
    for(int p = 0; p < plane_count; p++)
    {
        h->mc.copy[PIXEL_16x16](h->mb.pic.p_fdec[p], FDEC_STRIDE, h->mb.pic.p_fenc[p], FENC_STRIDE, 16);
    }
    if(chroma)
    {
        int height = 16 >> CHROMA_V_SHIFT;
        h->mc.copy[PIXEL_8x8](h->mb.pic.p_fdec[1], FDEC_STRIDE, h->mb.pic.p_fenc[1], FENC_STRIDE, height);
        h->mc.copy[PIXEL_8x8](h->mb.pic.p_fdec[2], FDEC_STRIDE, h->mb.pic.p_fenc[2], FENC_STRIDE, height);
    }
    return;
}
...
{% endcodeblock %}

### P_Skip 模式和 B_Skip 模式编码

* P_Skip 类型宏块：即 COPY 宏块，无像素残差，无运动矢量残差(MVD)。直接利用预测 MV 得到的像素预测值。像素重构值= 像素预测值。  
* B_Skip 类型宏块：无像素残差，无运动矢量残差(MVD)。解码时，通过 Direct 预测模式(时间或空间)计算出前、后向 MV 后，直接利用前、后向 MV 得到像素预测值。像素重构值 = 像素预测值。  



