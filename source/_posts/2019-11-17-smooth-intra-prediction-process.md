---
layout: post
title: "AV1(DAV1D)解码详解(十)之帧内编码平滑帧内编码Smooth_Intra_Prediction"
date: 2019-11-16 06:24:55 -0800
comments: true
categories: AV1
---

* list element with functor item
{:toc}

帧内预测种，除了方向预测模式外，AV1 还支持非定向帧内预测模式，它有 4 种不同的方法对当前值进行预测，其中包括 3 种平滑预测模式 SMOOTH_V、SMOOTH_H、SMOOTH 以及 PAETH 预测器。

<!--more-->

## 概述

## DAV1D 代码

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

