---
layout: post
title: "AV1(DAV1D) 解码详解(六)之帧内编码 Chrom_From_Luma"
date: 2019-11-12 14:00:19 -0800
comments: true
categories: av
---

* list element with functor item
{:toc}

AV1 在帧编码中使用了Luma_From_Luma 的工具，它是利用视觉图像中亮度值和色度值具有高度相似性的特点，通过选择适当的参数结合重建亮度值来预测色度值，该工具在游戏视频中具有很好地压缩效果。

<!--more-->

## 概述

Chrom_From_Luma(CFL) 的整个流程可以由下图表示。

{% img /images/av1_cfl/chroma_from_luma.png %}

## DAV1D 代码

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

