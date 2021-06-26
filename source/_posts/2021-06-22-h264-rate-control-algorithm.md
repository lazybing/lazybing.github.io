---
layout: post
title: "H.264 Rate Control Algorithm"
date: 2021-06-22 06:49:35 -0700
comments: true
categories: x264
---
* list element with functor item
{:toc}

码率控制是 H.264 编码器中非常重要的一个模块。X264 的码率控制算法大致分为帧级码率控制、宏块级码率控制。帧级码率控制算法比如：VBV 调整。宏块级别码率控制比如：MBTree 算法。

<!--more-->

# 基础知识

编码所需的 bits 与实际编码的复杂度和量化参数有关，复杂度越复杂，量化参数越小，所需 bits 越少。复杂度用运动补偿后残差的 SATD 表示。

qscale = 0.85 * 2^((qp - 12)/6.0)   (1)   
qp = 12 + 6 * log2(qscale / 0.85)   (2)  

x264 中的代码如下：

{% codeblock lang:c %}
static inline float qp2scale(float qp)
{
    return 0.85 * powf(2.0f, (qp - (12.0f + QP_BD_OFFSET)) / 6.0f);
}

static inline float qscale2qp(float qscale)
{
    return (12.0f + QP_BD_OFFSET) + 6.0f * log2f(qscale / 0.85f);
}
{% endcodeblock %}

