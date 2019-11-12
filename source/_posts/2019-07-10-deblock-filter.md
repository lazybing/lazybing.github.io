---
layout: post
title: "AV1(DAV1D) 解码详解(五)之DEBLOCK FILTER"
date: 2019-07-10 07:07:33 -0700
comments: true
categories: av1
---

* list element with functor item
{:toc}

AV1 使用了非常多的环路滤波器工具应用于解码帧。环路滤波的第一个阶段是去块滤波器(Deblocking Filter)。

<!--more-->

AV1 的去块滤波器与 VP9 中使用的滤波器基本相同，只是做了很小的改动————最长滤波从 VP9 的 15 抽头降成了 13 抽头。除了去块滤波器，AV1 还采用了CDEF 滤波器、Loop Restoration 滤波器、Film Grain 滤波器。  

去块滤波器(Deblocking Filter, DBF)又称去块效应滤波器，是一种减少在区块边界产生视觉上瑕疵的滤波器。这种视觉瑕疵称为区块效应，这种效应主要构成原因是以区块为基础的编解码器所造成的人造边界，以区块为基底的编解码器（AVC/HEVC/AV1）都会在解码过程中利用去块滤波器将区块效应的影响降低以改善视频影像的质量。  

### 介绍

以区块为基础的编解码器在预测(Prediction)或转换(Transform)编码时，都会将影像分成区块再做编码。因此影像重建时会造成在区块间边缘处不连续的现象，该现象称为去块效应，而这些区块边缘间视觉上的不连续称为人造边界。人造边界的主要成因有两个：

* 预测时出现不准的地方称为残量(Residual)，残量会利用离散余弦变换做量化，由于量化与反量化会产生误差，因此会在区块边界上产生视觉上的不连续。  
* 运动补偿，同一个画面内部相邻区块可能不是从前几个编码影像中相邻区块获取来做预测，因此会造成不连续的现象。同样的，画面内预测的方式也可能造成影像不连续。  

去区块滤波器主要有三个工作，分别是边界强度计算(Boundary Strength Computation)、边界分析(Boundary Analysis)以及滤波器应用(Filter Implementation)。  

1. 边界强度计算：主要是去计算边界强度(Boundary Strength, Bs)这个参数，边界强度呈现出相邻区块边界不连续的程序，而这个参数会跟量化的方式、区块类型、移动向量以及边界取样的梯度有关。  
2. 边界分析：因为区块边缘不连续的现象可能真的是对象边缘所产生，并非所谓的人造边界，这个工作主要是判断是否为人造边界。  
3. 滤波器的应用：做完前面两个工作可以决定边界强度以及判断是否真的为人造边界，这个工作主要对人造边界对应的边界强度选择该应用的滤波器。  

### 源码分析及优化

首先看 DAV1D 中，关于去块滤波的 C 实现函数：  

{% codeblock lang:c %}
static void loop_filter_h_sb128y_c(pixel *dst, const ptrdiff_t stride,
                                    const uint32_t *const vmast,
                                    const uint8_t (*l)[4], ptrdiff_t b4_stride,
                                    const AvFilterLUT *lut, const int h)
{
    const unsigned vm = vmask[0] | vmask[1] | vmask[2];
    for (unsigned y = 1; vm & ~(y - 1);
         y <<= 1, dst += 4 * PXSTRIDE(stride), l += b4_stride)
    {
        if (vm & y) {
            const int L = l[0][0] ? l[0][0] : l[-1][0];
            if (!L) continue;
            const int H = L >> 4;
            const int E = lut->e[L], I = lut->i[L];
            const int idx = (vmask[2] & y) ? 2 : !!(vmask[1] & y);
            loop_filter(dst, E, I, H, PXSTRIDE(stride), 1, 4 << idx);
        }
    }
}
{% endcodeblock %}

上面只是给出 Y 分量上的 水平滤波函数，从上面给出的 C 实现看，要实现 NEON 优化，并不简单，但如果再看它的汇编优化，简直太聪明了，在 DAV1D 发布0.3版本时，官方就称，仅仅去块滤波这一个模块，解码 8bit 流时，解码效率提升7%~34%之高。
后来我自己实现 10bit NEON 优化时，因为寄存器个数的限制（10bit，一个128位寄存器只能存放8个像素;而8bit，一个128位寄存器可存放16个像素），简码效率也有至少5%的提升。当时仿照 8bit 实现时，感慨汇编的技巧使用，惊为天人！

### 参考资料

1. [去块滤波器](https://zh.wikipedia.org/wiki/%E5%8E%BB%E5%8D%80%E5%A1%8A%E6%BF%BE%E6%B3%A2%E5%99%A8) 



