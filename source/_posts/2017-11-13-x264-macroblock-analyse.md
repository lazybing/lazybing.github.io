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

首先看一下`x264_macroblock_analyse`函数实现过程的大体过程：  

```C
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
>> * 调用`x264_mb_analyse_inter_p4x4()`分析 P4x4 帧间预测的代价。  
>> * 如果P4x4代价值小于P8x8，则调用`x264_mb_analyse_inter_p8x4()`和`x264_mb_analyse_inter_p4x8()`分析P8x4和P4x8帧间预测的代价。  
> e.如果P8x8代价值小于P16x16,调用`x264_mb_analyse_inter_p16x8()`和`x264_mb_analyse_inter_p8x16()`分析P16x8和P8x16帧间预测的代价。  
> f.此外，还要调用`x264_mb_analyse_intra()`，检查当前宏块作为 Intra 宏块编码的代价是否小于作为 P 宏块编码的代价。    

3. 如果当前是B Slice，则进行和 P Slice 类似的处理。  


