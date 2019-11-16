---
layout: post
title: "AV1(DAV1D) 解码详解(六)之帧内编码 Chroma_From_Luma"
date: 2019-11-12 14:00:19 -0800
comments: true
categories: av1
---

* list element with functor item
{:toc}

AV1 在帧编码中使用了Chroma_From_Luma 的工具，它是利用视觉图像中亮度值和色度值具有高度相似性的特点，通过选择适当的参数结合重建亮度值来预测色度值，该工具在游戏视频中具有很好地压缩效果。

<!--more-->

## 概述



Chrom_From_Luma(CFL) 的整个流程可以由下图表示。

当 chroma 分量通过下采样得到时，为使得像素分量一致，重建的 luma 分量需要对应的下采样。之后相应的重建 luma 像素减去平均值，得到 AC 分量。 scale 因子和符号，是通过码流中解码获得。CFL 预测值通过将重建 luma 像素的 AC 分量和 scale 因子相乘，并将结果与帧内的 DC 预测相加得到。如下图所示。

{% img /images/av1_cfl/chroma_from_luma.png %}

该流程分为三步：

1. Compute Luma AC Contribution。
2. Scale Chroma Plane
3. Add Chroma DC_PRED

## DAV1D 代码

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

## 结论

AV1 中采用的 Chroma_From_Luma 预测工具，该工具不仅降低了解码器复杂度，同时降低了预测错误率。
