---
layout: post
title: "AV1(DAV1D)解码详解(七)之帧内编码 Color Palette"
date: 2019-11-14 08:04:43 -0800
comments: true
categories:  av1
---

## 调色板模式概述

调色板模式，对于屏幕内容图像，很多编码块内部的颜色数是有限的，调色板模式枚举这些颜色生成颜色表，然后为每个样本传递一个索引以指示它属于颜色表中的哪种颜色。和基于预测-变换的传统编码方法相比，对于颜色数相对集中的屏幕内容图像，调色板模式往往更加有效。

## Color Palette

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

