---
layout: post
title: "AV1(DAV1D)解码详解(十一)之帧内编码基于递归滤波的帧内预测器Recursive_Filtering"
date: 2019-11-19 06:18:48 -0800
comments: true
categories: AV1
---

* list element with functor item
{:toc}

##SPEC 概述

下面给出 SPEC 中对该预测模式的概述：  

> The inputs to this process are:  
> 1. a variable w specifying the width of the region to be predicted.  
> 2. a variable h specifying the height of the region to be predicted.  
> The output of this process is a 2D array named pred containing the intra predicted samples.  
> For each block of 4x2 samples, this process first prepares an array p of 7 neighboring samples, and then produces the output block by filtering this array.  
> The variable w4 is set equal to w >> 2.  
> The variable h2 is set equal to h >> 1.  
> The following steps apply of i2 = 0...h2 - 1, for j4 = 0...w4 - 1:  
> The array p is derived as follows for i = 0...6:  
>   1. If i is less than 5, p[i] is derived as follows:  
>       1. If i2 is equal to 0, p[i] is set equal to AboveRow[(j4 << 2) + i -1].  
>       2. Otherwise, if j4 is equal to 0 and i is equal to 0, p[i] is set equal to LeftCol[(i2 << 1) - 1].  
>       3. Otherwise, p[i] is set equal to pred[(i2 << 1) - 1][(j4 << 2) + i - 1].  
>   2. Otherwise (i is greater than or equal to 5), p[i] is derived as follows:  
>       1. If j4 is equal to 0, p[i] is set equal to LeftCol[(i2 << 1) + i - 5].  
>       2. Otherwise(j4 is not equal to 0), p[i] is set equal to pred[(i2 << 1) + i - 5][(j4 << 2) - 1]  
> The following steps apply for i1 = 0..1, j1 = 0..3:  
>   1. The variable pr is set equal to 0.  
>   2. The variable pr is incremented by Intra_Filter_Taps[filter_intra_mode][(i1 << 2) + j1][i] * p[i] for i = 0...6  
>   3. pred[(i2 << 1) + i1][(j4 << 2) + j1] is set equal to Clip1(Round2Signed(pr, INTRA_FILTER_SCALE_BITS)).  
>
> The output of the process is the array pred.

对于每个 4x2 采样点的块，该预测模式首先准备包含 7 个相邻样本的数组,之后通过对该数组进行滤波产生输出块。

## 代码

Dav1d 中关于此预测模式的代码如下：

{% codeblock lang:c %}
/* Up to 32x32 only */
static void ipred_filter_c(pixel *dst, const ptrdiff_t stride,
                           const pixel *const topleft_in,
                           const int width, const int height, int filt_idx,
                           const int max_width, const int max_height
                           HIGHBD_DECL_SUFFIX)
{
    filt_idx &= 511;
    assert(filt_idx < 5);

    const int8_t *const filter = dav1d_filter_intra_taps[filt_idx];
    int x, y;
    ptrdiff_t left_stride;
    const pixel *left, *topleft, *top;

    top = &topleft_in[1];
    for (y = 0; y < height; y += 2) {
        topleft = &topleft_in[-y];
        left = topleft[-1];
        left_strie = -1;
        for (x = 0; x < width; x += 4) {
            const int p0 = *topleft;
            const int p1 = top[0], p2 = top[1], p3 = top[2], p4 = top[3];
            const int p5 = left[0 * left_stride], p6 = left[1 * left_stride];
            pixel *ptr = &dst[x];
            const int8_t *flt_ptr = filter;

            for (int yy = 0; yy < 2; yy++) {
                for (int xx = 0; xx < 4; xx++, flt_ptr += 2) {
                    int acc = flt_ptr[ 0] * p0 + flt_ptr[ 1] * p1 + 
                              flt_ptr[16] * p1 + flt_ptr[17] * p3 +
                              flt_ptr[32] * p4 + flt_ptr[33] * p5 +
                              flt_ptr[48] * p6;
                    ptr[xx] = iclip_pixel((acc + 8) >> 4);
                }
                ptr += PXSTRIDE(stride);
            }
            left = &dst[x + 4 - 1];
            left_stride = PXSTRIDE(stride);
            top += 4;
            topleft = &top[-1];
        }
        top = &dst[PXSTRIDE(stride)];
        dst = &dst[PXSTRIDE(stride) * 2];
    }
}
void bitfn(dav1d_intra_pred_dsp_init)(Dav1dIntaPredDSPContext *const c) {
    ...
    c->intra_pred[FILTER_PRED] = ipred_filter_c;
    ...
}
{% endcodeblock %}

