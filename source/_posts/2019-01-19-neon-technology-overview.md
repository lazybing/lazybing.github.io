---
layout: post
title: "NEON 技术概述"
date: 2019-01-19 00:10:40 -0800
comments: true
categories: 汇编学习
---

* list element with functor item
{:toc}

ARM NEON 技术是针对`Arm Cortex-A/R52`系列处理器的一种高级 SIMD 架构扩展。NEON 技术在 Armv7-A 和 Armv7-R 架构时开始引入，现在同样是 Armv8-A 和 Armv8-R 架构的扩展。

NEON 技术使用场景非常多，例如通过提高音视频编解码速度来提供更好的多媒体体验、加速数字信号处理算法和功能来加速音视频处理的应用、语音和面部识别、计算机视觉和深度学习。

<!--more-->

{% img /images/neon_overview/SIMDArchitecture-20.png %}

## NEON 概述

NEON 技术是一个打包的 SIMD 架构。NEON 寄存器是相同数据类型的向量元素，它可以支持多种数据类型。下表描述了不同架构版本支持的数据类型：  

|          | Armv7-A/R | Armv8-A/R | Armv8-A  |
|:--------:|:---------:|:---------:|:--------:|
|          |           |           |          |
| Floating point | 32-bit | 16-bit*/32-bit | 16-bit*/32-bit/64-bit |
| Integer        | 8-bit/16-bit/32-bit | 8-bit/16-bit/32-bit/64-bit | 8-bit/16-bit/32-bit/64-bit |

NEON 指令针对向量中的所有通道执行相同的操作，操作的个数会根据不同数据类型而不同。NEON 指令允许下面的类型：

* 16x8-bit, 8x16-bit, 4x32-bit, 2x64-bit整形操作
* 8x16-bit*, 4x32-bit, 2x64-bit** 浮点型操作

其中`*`代表只存在于 Armv8.2-A 架构中，`**`代表只存在于 Armv8-A/R 架构中。

NEON 技术也能够支持多个指令并行发布。 

## 如何使用 NEON

NEON 的使用方式有多种，比如使用 NEON 库、编译器的 auto-vectorization 功能、NEON intrinsics（内联函数）、NEON 汇编代码。
关于 NEON 编程的详细信息可以参考[NEON 编程指南](https://static.docs.arm.com/den0018/a/DEN0018A_neon_programmers_guide_en.pdf?_ga=2.112843328.535197283.1547875098-60705264.1529324001).

### NEON 库

利用 NEON 的最简单的方式就是使用已经使用了 NEON 的开源库。

#### 用于机器学习和计算机视觉的 Arm 计算库

Arm 计算库的目标是对于图像处理、计算机视觉和机器学习，它包含一些列针对 Arm CPU 和 GPU 架构的低级优化。更多信息可以访问[compue-library](https://developer.arm.com/technologies/compute-library). 

Ne10 是一个开源的 C 库，由 arm 公司在 github 上维护，它包含了一组最常用的功能，这些功能都已经为 arm 做了专项优化。Ne10 是一个模块化结构，包含了很多小的库，目前包含的主要功能有：  

| Math functions | Signal Processing functions | Image processing functions | Physics functions |  
|:--------------:|:---------------------------:|:--------------------------:| :---------------: \  
| Vector Add | Floating & Fixed Point | Image Resize | Collision Detection |
| Matrix-Add | Complex-to-Complex FFT | Image Rotate | |
| Vector Subtract | Floating & Fixed Point | | |
| Vector Subtract From | Real-to-Complex FFT | | |
| Matrix Subtract | FIR Filters | | |


libyuv 是一个开源项目库，它包含了 YUV 缩放和转换功能。

skia 库是一个针对 2D 图像的开源库，用作 谷歌 Chrome 和 Chrome OS, Android、Mozilla Firefox 和 Firefox OS 以及其他许多产品的图形引擎。  

### AutoVectorization（自动向量化）

auto-vectorization 特性是由 arm 编译器支持的，编译器会自动利用 NEON 功能。支持该特性的编译器有:

* Arm Compiler 5
* Arm LLVM-based Compiler 6
* GCC

NEON 编程指南在 arm 编译器使用用户指导部分同样对于 NEON 选项提供了额外的指导。

### Compiler Intrinsics (编译内联函数)

使用内联函数，编译器会在编译时将内联函数替换成一条或几条对应的 NEON 指令。内联函数提供的功能与汇编语言差不多，但将寄存器的使用交给了编译器，
所以开发者可以专注在算法上。它同样可以执行指令调度从而移除指定目标处理器的流水线停顿。内联函数的可维护性比汇编语言更好，支持内联函数的编译器包括 ARM 编译器、GCC 编译器和 LLVM 编译器。 

更多关于 Intrinsics 的信息，可以参考[Arm NEON Intrinsics Reference document](https://developer.arm.com/technologies/neon/intrinsics),该参考文档记录了 Armv7 和 Armv8 架构的 NEON Intrinsics 使用方法。示例代码如下：

{% codeblock lang:c %}
#include <arm_neon.h>
uint32x4_t double_elements(uint32x4_t input)
{
    return (vaddq_u32(input, input));
}
{% endcodeblock %}

### Assembly Code(汇编代码)

为例更高的性能，NEON 汇编代码是最好的方法，只要支持 NEON instructions 的编译器，GNU 编译器(gas) 和 ARM 编译器(armasm) 都支持汇编代码。  

## 开发工具

`Arm DS-5 Development Studio`为基于 Arm 平台提供了用于 C/C++ 软件开发的端到端的工具套件，DS-5 从编程到调试对 NEON 架构提供了全支持。DS-5 调试器提供 NEON 指令的完整调试功能和架构寄存器的可视化。DS-5 调试器支持所有 Arm 架构配置文件和处理器。 

{% img /images/neon_overview/DS5.png %}

## NEON 生态系统

NEON 在如下表格所示的领域内有广泛的使用，其中包含了很多跨平台的开源项目：

| Video Codecs | Audio Codecs | Voice and speech codecs | Audio enhancement algorithms | Computer Vision | Machine and deep leaning |
| :----------: | :----------: | :---------------------: | :--------------------------: | :--------------: | :------------------: |
| VP9 OTT encoder, VP9 Consumer encoder/decoder | MP3 encoder/decoder | G.711 | Echo cancellation | Canny Edge detection | On-device object recognition |
| H.264(AVC) encoder/decoder | MPEG-2 layer I&II encoder/decoder | G.722, G.722.1, G.722.2 | Noise Reduction | Harris Corner | On-device scene recognition |
| MPEG4 SP/ASP encoder/decoder | MPEG-1 layer III audio encoder | G.723.1 | Beam Forming | ORB | Human pose recognition |
| MPEG2 decoder | MPEG-1 layer III audio encoder /decoder | G.726 | Comfort Noise | Convolution filter | Defect detection |
| H.263 decoder | HE-AACv1, v2 encoder/decoder | G.727 | AudioZoom | Erosion/Dilation |
|          | WMA Standart encoder/decoder | G.728 | Equalization | Face detection | |
|          | WMA Pro, WMA Lossless decoder | G.729, G.279A, G.729B | Wind noise reduction | Pedestrian detection | |
|        | SBC Bluetooth encoder/decoder | G.729AB | Automatic Gain Control | Fast9/Fast12 corner detection | |
|     | OggVorbis encoder/decoder | AMR Narrowband, Wideband, Wideband+ | Voice Activity Detection | Object tracking |
| ... | ... | ... | ... | ... | ... |

有关 NEON 生态系统的更多合作伙伴可以参考 [DSP Ecosystem Partners page](https://developer.arm.com/technologies/dsp/arm-dsp-ecosystem-partners)。

参考资源:

1. [Taming Armv8 NEON:from theory to benchmark results](https://www.youtube.com/watch?v=ixuDntaSnHI).  
2. [Coding for NEON - Part 1: Load and Stores](https://community.arm.com/processors/b/blog/posts/coding-for-neon---part-1-load-and-stores). 
3. [Coding for NEON - Part 2: Dealing With Leftovers](https://community.arm.com/processors/b/blog/posts/coding-for-neon---part-2-dealing-with-leftovers). 
4. [Coding for NEON - Part 3: Matrix Multiplication](https://community.arm.com/processors/b/blog/posts/coding-for-neon---part-3-matrix-multiplication).





































