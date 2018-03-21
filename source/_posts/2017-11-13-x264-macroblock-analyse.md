---
layout: post
title: "X264 源码解析之x264_macroblock_analyse函数"
date: 2017-11-13 07:06:23 -0800
comments: true
categories: X264
---

* list element with functor item
{:toc}

本文主要记录 X264 中对于`x264_macroblock_analyse`函数的分析，该函数主要完成 2 个任务：对于帧内宏块，分析帧内预测模式；对于帧间宏块，进行运动估计、分析帧间预测模式。   
<!--more-->

## 宏块分析概述

首先看一下`x264_macroblock_analyse`函数实现过程的大体过程：  

```
void x264_macroblock_analyse(x264_t *)
{
    h->mb.i_qp = x264_ratecontrol_mb_qp(h); //get QP of the MB
    ...
    x264_mb_analyse_init(h, &analysis, h->mb.i_qp);

    if(h->sh.i_type == SLICE_TYPE_I)
    {
        x264_mb_analyse_intra(h, &analysis, CONST_MAX);
    }
    else if(h->sh.i_type == SLICE_TYPE_P)
    {
        x264_macroblock_probe_pskip(h);

        x264_mb_analyse_inter_p16x16(h, &analysis);

        x264_mb_analyse_inter_p8x8(h, &analysis);

        x264_mb_analyse_inter_p4x4(h, &analysis, i);
        
        x264_mb_analyse_inter_p8x4(h, &analysis, i);

        x264_mb_analyse_inter_p4x8(h, &analysis, i);

        x264_mb_analyse_inter_p16x8(h, &analysis, i_cost);

        x264_mb_analyse_inter_p8x16(h, &analysis, i_cost);

        x264_me_refine_qpel(h, &analysis.xxxx);
    }
    else if(h->sh.i_type == SLICE_TYPE_B)
    {
        x264_mb_analyse_inter_b16x16(h, &analysis);
        x264_mb_analyse_inter_b8x8( h, &analysis );
        x264_mb_analyse_inter_b16x8( h, &analysis );
    }
}
```

上面只是给出了该函数中调用的函数，并没有给出实际编码中的逻辑判断。它的实现如下：  

1. 如果当前是I Slice, 调用`x264_mb_analyse_intra()`进行Intra宏块的帧内预测模式分析。  
2. 如果当前是P Slice, 则进行下面流程的分析：

> a.调用`x264_macroblock_probe_pskip()`分析是否为skip宏块，如果是skip宏块，则不再进行下面分析。  
> b.调用`x264_mb_analyse_inter_p16x16()`分析P16x16帧间预测的代价。  
> c.调用`x264_mb_analyse_inter_p8x8`分析P8x8帧间预测的代价。  
> d.如果 P8x8 代价值小于 P16x16，则依次对 4 个 8x8 的子宏块分割进行判断：   
>  * 调用`x264_mb_analyse_inter_p4x4()`分析 P4x4 帧间预测的代价。  
>  * 如果P4x4代价值小于P8x8，则调用`x264_mb_analyse_inter_p8x4()`和`x264_mb_analyse_inter_p4x8()`分析P8x4和P4x8帧间预测的代价。  
> e.如果P8x8代价值小于P16x16,调用`x264_mb_analyse_inter_p16x8()`和`x264_mb_analyse_inter_p8x16()`分析P16x8和P8x16帧间预测的代价。  
> f.此外，还要调用`x264_mb_analyse_intra()`，检查当前宏块作为 Intra 宏块编码的代价是否小于作为 P 宏块编码的代价。    

3. 如果当前是B Slice，则进行和 P Slice 类似的处理。  

## 帧内预测  

帧内预测模式种，预测块 P 是基于已编码重建块和当前块形成的，对亮度像素来说，P 块用于 4x4 子块或者 16x16 宏块的相关操作。其中 4x4 宏块，有 9 种可选预测模式，适用于
带有大量细节的图像编码；16x16 宏块适用于比较平坦的图像，该宏块有 4 种预测模式，预测整个 16x16 亮度块。色度块也有 4 种预测模式，与 16x16 亮度块预测模式类似。编码器
通常会选择使 P 块和编码块之间差异最小的预测模式。  

除此之外，还有一种帧内预测模式称为 I_PCM 编码模式。该模式下，编码器直接传输图像像素值，而不经过预测和变换。在一些特殊的情况下，特别是
图像内容不规则或者量化参数非常低时该模式比常规操作(帧内预测-变换-量化-熵编码)效率更高。I_PCM 模式用于以下目的：  

1. 允许编码器精确的表示像素值  
2. 提供表示不规则图像内容的准确值，而不引起重大的数据量增加  
3. 严格限制宏块解码比特数，但不损害编码效率  

关于帧内预测的原理介绍部分，参考[X264 源码解析之帧内预测](http://lazybing.github.io/blog/2017/06/30/x264-intra-prediction/)。

`x264_mb_analyse_intra`中关于帧内预测模式的选择判断，整体思路是，遍历所有可能的预测模式，包括 4 种 16x16 的预测模式、9 种 4x4 的预测模式，具体流程如下：  

### Intra16x16 预测模式分析
对于非`AVC-Intra Compat`，首先根据当前宏块左边、上边宏块的可参考情况，判断该宏块可能存在的预测模式。
对于每个宏块，根据重建宏块和预测模式，调用`predict_16x16[]`做帧内预测;调用`x264_pixel_function_t`中的`mbcmp[]`计算编码代价。
选择最小的编码代价，记录编码代价的值，并记录编码模式。核心代码如下：  

{% codeblock lang:c %}
...
for(; *predict_mode >= 0; predict_mode++)
{
    int i_satd;
    int i_mode = *predict_mode;

    if(h->mb.b_lossless)
        x264_predict_lossless_16x16(h, 0, i_mode);
    else
        h->predict_16x16[i_mode](p_dst);

    i_satd = h->pixf.mbcmp[PIXEL_16x16](p_dst, FDEC_STRIDE, psr, FENC_STRIDE) +
        lambda * bs_size_ue(x264_mb_pred_mode16x16_fix[i_mode]);
    COPY2_IF_LT(a->i_satd_i16x16, i_satd, a->i_predict16x16, i_mode);
    a->i_satd_i16x16_dir[i_mode] = i_satd;
}
...
{% endcodeblock %}

### Intra4x4 预测模式分析

循环处理 16 个 4x4 的块：首先调用`x264_mb_predict_intra4x4_mode()`函数根据周围宏块情况判断该宏块可用的预测模式。之后循环计算 9 种 Intra4x4 的帧内预测模式，调用`predict_4x4[]`函数根据重建帧宏块进行帧内预测，调用`x264_pixel_funtion_t`中的`mbcmp[]`计算编码代码。
获取最小代缴的 Intra4x4 模式。将 16 个 4x4 宏块的最小代价相加，得到总代价。核心代码如下：  

{% codeblock lang:c %}
...
const int8_t *predict_mode = predict_4x4_mode_available(a->b_avoid_topright, h->mb.i_neighbour4[idx], idx);
...
for( ; *predict_mode >= 0; predict_mode++ )
{
    int i_satd;
    int i_mode = *predict_mode;

    if( h->mb.b_lossless )
        x264_predict_lossless_4x4( h, p_dst_by, 0, idx, i_mode );
    else
        h->predict_4x4[i_mode]( p_dst_by );

    i_satd = h->pixf.mbcmp[PIXEL_4x4]( p_dst_by, FDEC_STRIDE, p_src_by, FENC_STRIDE );
    if( i_pred_mode == x264_mb_pred_mode4x4_fix(i_mode) )
    {
        i_satd -= lambda * 3;
        if( i_satd <= 0 )
        {
            i_best = i_satd;
            a->i_predict4x4[idx] = i_mode;
            break;
        }
    }

    COPY2_IF_LT( i_best, i_satd, a->i_predict4x4[idx], i_mode );
}
...
{% endcodeblock %}

## 帧间预测

帧间预测时指利用视频时间域相关性，使用临近已编码图像像素预测当前图像的像素，以达到有效去除视频时域冗余的目的。
由于视频序列通常包括较强的时域相关性，因此预测残差值接近于0，将残差信号作为后续模块的输入进行变换、量化、扫描、熵编码，可实现对视频信号的高效压缩。  

接下来主要介绍基于`Baseline Profile`支持的 P 帧预测模式工具以及`Main Profile`和`Extended Profile`支持的 B 帧和加权预测等帧间预测工具。  

### 运动补偿块

每个宏块(16x16 像素)可分割为 4 种方式：一个 16x16,两个 16x8, 两个 8x16,四个 8x8。其运动补偿也有相应的四种。8x8 模式的每个子宏块还
可以继续分割，分割方式为：一个 8x8，两个 4x8，两个 8x4，四个 4x4。  

每个分割或子宏块都有一个独立的运动补偿。每个 MV 必须被编码、传输，分割的选择也需要编码到压缩码流中。对于大的尺寸而言，MV 选择和分割
类型只需少量的比特，但运动补偿残差在多细节区域能量将非常高。小尺寸分割运动补偿残差能量低，但需要较多的比特表示 MV 和分割选择。分割
尺寸的选择影响了压缩性能。整体而言，大的分割尺寸适合平坦的区域，而小尺寸适合多细节区域。  

宏块的色度成分(Cr 和 Cb)则为相应亮度的一半(水平和垂直各一半)。色度块采用和亮度块同样的分割模式，只是尺寸减半(水平和垂直方向都减半)。
例如，8x16 的亮度块相应色度块尺寸为 4x8，8x4 亮度块相应色度块尺寸为 4x2 等等。色度块的 MV 也是通过相应亮度 MV 水平和垂直分量减半而得。  

### 运动矢量  

帧间编码宏块的每个分割或子宏块都是从参考图像某一相同尺寸区域预测而得。两者之间的差异(MV)对亮度成分采用 1/4 像素精度，色度 1/8 像素精度。
亚像素位置的亮度和色度像素并不存在于参考图像中，需利用临近已编码点进行内插而得。如果 MV 的垂直和水平分量为正数，则参考块相应像素实际存在，
如果其中一个或两个为分数，则预测像素要通过参考帧中相应像素内插获得。  

### MV 预测

每个分割 MV 的编码需要相当数目的比特，特别是使用小分割尺寸时。为了减少传输比特数，可利用邻近分割的 MV 较强的相关性，MV 可由邻近已编码分割
的 MV 预测而得。预测矢量 MVp 基于已计算 MV 和 MVD（预测与当前的差异）并被编码和传送。MVp 则取决于运动补偿尺寸和邻近 MV 的有无。  

示例如下：

{% img /images/macroblock_analyse/mv_prediction_macroblock.png %}  

E 为当前宏块或宏块分割子宏块。A、B、C 分别为 E 的左、上、右上方的三个相对应块。如果 E 的左边不止一个分割，取其中最上的一个为 A；上方
不止一个分割时，取最左边一个为 B。

1)  传输分割不包括 16x8 和 8x16 时，MVP 为 A、B、C 分割 MV 的中值；  
2） 16x8 分割，上面部分 MVp 由 B 预测，下面部分 MVp 由 A 预测；  
3） 8x16 分割，左面部分 MVp 由 A 预测，右面部分 MVp 由 B 预测；  
4） skipped MB 类型同 1 。  

### 帧间预测函数分析  

帧间预测的帧类型大多是 P 帧或 B 帧。对于 P 帧，它的宏块分析流程为：  

1. 调用`x264_macroblock_probe_pskip()`分析是否为 Skip 宏块，如果是则不进行后面的分析。  
2. 调用`x264_mb_analyse_inter_p16x16()`分析 P16x16 帧间预测的代价。  
3. 调用`x264_mb_analyse_inter_p8x8()`分析 P8x8 帧间预测的代价。  
4. 如果 P8x8 代价小于 P16x16, 则依次对 4 个 8x8 的子宏块分割进行判断：  
    i. 调用`x264_mb_analyse_inter_p4x4()`分析 P4x4 的帧间预测代价。  
    ii. 如果 P4x4 代价值小于 P8x8，则调用`x264_mb_analyse_inter_p8x4()`和`x264_mb_analyse_inter_p4x8()`分析 P8x4 和 P4x8 帧间预测的代价。  
5. 如果 P8x8 代价值小于 P16x8，调用`x264_mb_analyse_inter_p16x8()`和`x264_mb_analyse_inter_p8x16()`分析 P16x8 和 P8x16 帧间预测的代价。  

