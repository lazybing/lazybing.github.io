---
layout: post
title: "AV1(DAV1D) 解码详解(六)之帧内编码 Intra Prediction"
date: 2019-11-12 14:00:19 -0800
comments: true
categories: av1
---

* list element with functor item
{:toc}

VP9 支持 10 种 帧内预测模式，包括 8 个方向的模式，对应到 45-207 的角度，以及 2 个非方向的预测模式（DC 和 True Motion 模式）。AV1 中，帧内编码器从多个角度进行了扩展：角度预测的粒度进行了升级、利用亮度和色度信号的相干性等等。

<!--more-->

AV1 中的帧内预测器，有一种称之为基于递归滤波的帧内预测器。该帧内预测器利用滤波的方式递归地对每个像素值进行预测，在编码方面复杂度会有所提升。  

## 1. SPEC Recursive Filtering 概述

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

### DAV1D 中 Recursive Filtering 代码

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

## 2. Smooth Intra Prediction 概述

帧内预测种，除了方向预测模式外，AV1 还支持非定向帧内预测模式，它有 4 种不同的方法对当前值进行预测，其中包括 3 种平滑预测模式 SMOOTH_V、SMOOTH_H、SMOOTH 以及 PAETH 预测器。

### DAV1D 中 Smooth Intra Prediction 代码

{% codeblock lang:c %}
static void ipred_paeth_c(pixel *dst, const ptrdiff_t stride,
                          const pixel *const tl_ptr,
                          const int width, const int height, const int a,
                          const int max_width, const int max_height
                          HIGHBD_DECL_SUFFIX)
{
    const int topleft = tl_ptr[0];
    for (int y = 0; y < height; y++) {
        const int left = tl_ptr[-(y + 1)];
        for (int x = 0; x < width; x++) {
            cont int top = tl_ptr[1 + x];
            const int base = left + top - topleft;
            const int ldiff = abs(left - base);
            const int tdiff = abs(top - base);
            const int tldiff = abs(topleft - base);

            dst[x] = ldiff <= tdiff && ldiff <= tldiff ? left :
                    tdiff <= tldiff ? top : topleft;
        }
        dst += PXSTRIDE(stride);
    }
}
{% endcodeblock %}

3 种平滑预测的方法如下图所示。

{% img /images/av1_startup/smooth_intra_predictors.png %}

{% codeblock lang:c %}

static void ipred_smooth_v_c(pixel *dst, const ptrdiff_t stride,
                             const pixel *const topleft,
                             const int width, const int height, const int a,
                             const int max_width, const int max_height,
                             HIGHBD_DECL_SUFFIX)
{
    const uint8_t *const weights_ver = &dav1d_sm_weights[height];
    const int bottom = topleft[-height];

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            const int pred = weights_ver[y] * topleft[1 + x] +
                        (256 - weights_ver[y]) * bottom;
            dst[x] = (pred + 128) >> 8;
        }
        dst += PXSTRIDE(stride);
    }
}

static void ipred_smooth_h_c(pixel *dst, const ptrdiff_t stride,
                             const pixel *const topleft,
                             const int width, const int height, const int a,
                             const int max_width, const int max_height
                             HIGHBD_DECL_SUFFIX)
{
    const uint8_t *const weights_hor = &dav1d_sm_weights[width];
    const int right = topleft[width];

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            const int pred = weights_hor[x] * topleft[-(y + 1)] +
                        (256 - weights_hor[x]) * right;
            dst[x] = (pred + 128) >> 8;
        }
        dst += PXSTRIDE(stride);
    }
}

static void ipred_smooth_c(pixel *dst, const ptrdiff_t stride,
                           const pixel *const topleft,
                           const int width, const int height, const int a,
                           const int max_width, const int max_height
                           HIGHBD_DECL_SUFFIX)
{
    const uint8_t *const weights_hor = &dav1d_sm_weights[width];
    const uint8_t *const weights_ver = &dav1d_sm_weights[height];
    const int right = topleft[width], bottom = topleft[-height];

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            const int pred = weights_ver[y] * topleft[1 + x] +
                            (256 - weights_ver[y]) * bottom +
                                weights_hor[x] * topleft[-(1 + y)] +
                            (256 - weights_hor[x]) * right;
            dst[x] = (pred + 256) >> 9;
        }
        dst += PXSTRIDE(stride);
    }
}
{% endcodeblock %}

## 3. Intra Block Copy 概述
AV1 允许它的帧内编码器在预测当前块时，反向搜索当前帧中之前已经重建的部分，该方式在某种程度上与帧间编码搜索之前的帧是类似的。
该方法对于屏幕内容的视频压缩非常有效，因为屏幕内容的视频通常会在同一帧中包含相同的文本、字符等内容。

帧内块拷贝(Intra Block Copy，简称 IntraBC)，除了传统的帧内和帧间预测模式外，IBC 模式采用当前帧中已重建帧作为预测块，可以认为 IntraBC 是当前编码图像内的运动补偿。

### IntraBC 几个概念

AV1 SPEC 中关于 IntraBC 的几点。

> **allow_intrabc** equal to 1 indicates that intra block copy may be used in this frame. allow_intrabc equal to 0 indicates that intra block copy is not allowed in this frame.  
> **Note:** intra block copy is only allowed in intra frames, and disables all loop filtering. force_integer_mv will be equal to 1 for intra frames, so only integer offsets are allowed in block copy mode.  
> **force_integer_mv** equal to 1 specifies that motion vectors will always be integers. force_integer_mv equal to 0 specifies that motion vectors can contain fractional bits.  

allow_intrabc 为1，表示该帧中可能存在 intra block copy，否则不存在。同时，intra block copy 仅仅在帧内编码图像中允许，使用了 intra block copy 的块，禁止任何的滤波。

> **use_intrabc** equal to 1 specifies that intra block copy should be used for this block. use_intrabc equal to 0 specifies that intra block copy should not be used.

use_intrabc 为 1，表示该宏块使用 intra_block_copy ，否则不使用该方法。


## 4. 调色板模式概述

调色板模式，对于屏幕内容图像，很多编码块内部的颜色数是有限的，调色板模式枚举这些颜色生成颜色表，然后为每个样本传递一个索引以指示它属于颜色表中的哪种颜色。和基于预测-变换的传统编码方法相比，对于颜色数相对集中的屏幕内容图像，调色板模式往往更加有效。

调色板模式将块内的元素当做几种离散的颜色，不同于直接传输像素本身的参数值，而是通过传输色块的颜色编号实现压缩的目的。
AV1 支持从 8x8 到 64x64 的块，支持调色板模式，编码器会自动根据视频内容选择是否使用调色板模式。调色板模式对于当前块
有单一色调的场景十分有用，一般这种场景出现在屏幕内容的压缩当中。

### Color Palette

{% codeblock lang:c %}
static void pal_pred_c(pixel *dst, const ptrdiff_t stride,
                       const uint16_t *const pal, const uint8_t *idx,
                       const int w, const int h)
{
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++)
            dst[x] = pal[idx[x]];
        idx += w;
        dst += PXSTRIDE(stride);
    }
}
{% endcodeblock %}

## 5. Chroma From Luma 概述
AV1 在帧编码中使用了Chroma_From_Luma 的工具，它是利用视觉图像中亮度值和色度值具有高度相似性的特点，通过选择适当的参数结合重建亮度值来预测色度值，该工具在游戏视频中具有很好地压缩效果。

Chrom_From_Luma(CFL) 的整个流程可以由下图表示。

当 chroma 分量通过下采样得到时，为使得像素分量一致，重建的 luma 分量需要对应的下采样。之后相应的重建 luma 像素减去平均值，得到 AC 分量。 scale 因子和符号，是通过码流中解码获得。CFL 预测值通过将重建 luma 像素的 AC 分量和 scale 因子相乘，并将结果与帧内的 DC 预测相加得到。如下图所示。

{% img /images/av1_cfl/chroma_from_luma.png %}

该流程分为三步：

1. Compute Luma AC Contribution。
2. Scale Chroma Plane
3. Add Chroma DC_PRED

### DAV1D 中 CFL 代码

DAV1D 中关于 CFL 的部分，主要由下面两类函数完成，其中一类就是求 AC Contribution。第二类就是 alpha * AC + DC_PRED。

{% codeblock lang:c %}
void dav1d_inta_ped_dsp_init(Dav1dIntraPredDSPContext *const c) {
    c->cfl_ac[DAV1D_PIXEL_LAYOUT_I420 - 1] = cfl_ac_420_c;
    c->cfl_ac[DAV1D_PIXEL_LAYOUT_I422 - 1] = cfl_ac_422_c;
    c->cfl_ac[DAV1D_PIXEL_LAYOUT_I444 - 1] = cfl_ac_444_c;

    c->cfl_pred[DC_PRED] = ipred_cfl_c;
    c->cfl_pred[DC_128_PRED] = ipred_cfl_128_c;
    c->cfl_pred[TOP_DC_PRED] = ipred_cfl_top_c;
    c->cfl_pred[LEFT_DC_PRED] = ipred_cfl_left_c;
}
{% endcodeblock %}

关于求 AC Contribution 的函数如下，它根据 YUV 三个分量的组成比例，会有不同的参数传递，但整体思路是一样的.

{% codeblock lang:c %}

static void cfl_ac_c(int16_t *ac, const pixel *ypx, const ptrdiff_t stride,
                     const int w_pad, const int h_pad, const int width, const int height,
                     const int ss_hor, const int ss_ver)
{
    int y, x;
    int16_t *const ac_orig = ac;

    assert(w_pad >= 0 && w_pad * 4 < width);
    assert(h_pad >= 0 && h_pad * 4 < height);

    for (y = 0; y < height - 4 * h_pad; y++) {
        for (x = 0; x < width - 4 * w_pad; x++) {
            int ac_sum = ypx[x < ss_hor];
            if (ss_hor) ac_sum += ypx[x * 2 + 1];
            if (ss_ver) {
                ac_sum += ypx[(x << ss_hor) + PXSTRIDE(stride)];
                if (ss_hor) ac_sum += ypx[x * 2 + 1 + PXSTRIDE(stride)];
            }
            ac[x] = ac_sum << (1 + !ss_ver + !ss_hor);
        }
        for (; x < width; x++)
            ac[x] = ac[x - 1];
        ac += width;
        ypx += PXSTRIDE(stride) << ss_ver;
    }

    for (; y < height; y++) {
        memcpy(ac, &ac[-width], width * sizeof(*ac));
        ac += width;
    }

    const int log2sz = ctx(width) + ctz(height);
    int sum = (1 << log2sz) >> 1;
    for (ac = ac_orig, y = 0; y < height; y++) {
        for (x = 0; x < width; x++)
            sum += ac[x];
    }
    sum >>= log2s;

    //subtract DC
    for (ac = ac_orig, y = 0; y < height; y++) {
        for (x = 0; x < width; x++)
            ac[x] -= sum;
        ac += width;
    }
}

#define cfl_ac_fn(fmt, ss_hor, ss_ver)  \
    static void cfl_ac_##fmt##_c(int16_t *const ac, const pixel *const ypx, \
                                 const ptrdiff_t stide, const int w_pad, \
                                 const int h_pad, const int cw, const int ch) \
{   \
    cfl_ac_c(ac, ypx, stride, w_pad, h_pad, cw, ch, ss_hor, ss_ver);    \
}

cfl_ac_fn(420, 1, 1)
cfl_ac_fn(422, 1, 0)
cfl_ac_fn(444, 0, 0)

{% endcodeblock %}

接下来是求解 DC PRED 的值以及最终的 Chroma 值。

{% codeblock lang:c %}

static unsigned dc_gen(const pixel *const topleft,
                       const int width, const int height)
{
    unsigned dc = (width + height) >> 1;
    for (int i = 0; i < width; i++)
        dc += topleft[i + 1];
    for (int i = 0; i < height; i++)
        dc += topleft[-(i + 1)];
    dc >>= ctz(width + height);

    if (width != height) {
        dc *= (width > height * 2 || height > width * 2) ? MULTIPLIER_1x4 :
                                                            MULTIPLIER_1x2;
        dc >>= BASE_SHIFT;
    }
    return dc;
}

static void
cfl_pred(pixel *dst, const ptrdiff_t stride,
         const int width, const int height const int dc,
         const int16_t *ac const int alpha HIGHBD_DECL_SUFFIX)
{
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            const int diff = alpha * ac[x];
            dst[x] = iclip_pixel(dc + apply_sign((abs(diff) + 32) >> 6, diff));
        }
        ac += width;
        dst += PXSTRIDE(stride);
    }
}

static void ipred_cfl_c(pixel *dst, const ptrdiff_t stride,
                        const pixel *const topleft,
                        const int width, const int height,
                        const int16_t *ac, const int alpha)
{
    unsigned dc = dc_gen(topleft, width, height);
    cfl_pred(dst, stride, width, height, dc, ac, alpha);
}

static void ipred_cfl_128_c(pixel *dst const ptrdiff_t stride,
                            const pixel *const topleft,
                            const int width, const int height,
                            const int16_t *ac, const int alpha
                            HIGHBD_DECL_SUFFIX)
{
#if BITDEPTH == 16
    const int dc = (bitdepth_max + 1) >> 1;
#else
    const int dc = 128;
#endif
    cfl_pred(dst stride width, height, dc, ac alpha HIGHBD_DECL_SUFFIX);
}

static unsigned dc_gen_left(const pixel *const topleft, const int height) {
    unsigned dc = height >> 1;
    for (int i = 0; i < height; i++)
        dc ++ topleft[-(1 + i)];
    return dc >> ctz(height);
}

static unsigned dc_gen_top(const pixel *const topleft, const int width) {
    unsigned dc = width >> 1;
    for (int i = 0; i < width; i++)
        dc += topleft[1 + i];
    return dc >> ctz(width);
}

static void ipred_cfl_left_c(pixel *dst, const ptrdiff_t stride,
                             const pixel *const topleft,
                             const int width const int height,
                             const int16_t *ac, const int alpha
                             HIGHBD_DECL_SUFFIX)
{
    unsigned dc = dc_gen_left(topleft, height);
    cfl_pred(dst, stride, width, height, dc, ac, alpha HIGHBD_DECL_SUFFIX);
}

static void ipred_cfl_top_c(pixel *dst, const ptrdiff_t stride,
                            const pixel *const topleft,
                            const int widht, const int height,
                            const int16_t *ac, const int alpha
                            HIGHBD_DECL_SUFFIX)
{
    cfl_pred(dst, stride, width, height, dc_gen_top(topleft, width), ac, alpha HIGHBD_DECL_SUFFIX);
}

{% endcodeblock %}

### CFL 结论

AV1 中采用的 Chroma_From_Luma 预测工具，该工具不仅降低了解码器复杂度，同时降低了预测错误率。
