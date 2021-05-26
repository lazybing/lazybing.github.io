---
layout: post
title: "Intra-frame Prediction Algorithm"
date: 2021-05-26 07:38:25 -0700
comments: true
categories: 论文
---

* list element with functor item
{:toc}

本论文详细分析了帧内预测算法的原则和流程，同时提出了一个提升算法，并阐述了优势。通过实现关于H.264/AVC的标准和和应用实验，证明算法具有实用价值和促进作用。

"Intra-frame Prediction Algorithm Based on the H.264/AVC Research and Improvement"

<!--more-->

## Introduction

在帧内编码的过程中，有很多帧内预测模式已被采用提高效率。通过这种方法，空间图像信息的冗余将被删除。亮度预测被分为四个部分，它们分别是 4x4 帧内预测、16x16 帧内预测、8x8 帧内预测和 I-PCM 模式。

4x4 模式用于小的预测宏块，来处理详细而复杂的图像。在图像编码中，处理平坦区域使用更大的宏块的帧内 16x16 模式。I-PCM 模式是一个特别模式，它在特殊情况下使用，当原始数据直接传输比预测编码传输还要低时使用。帧内 8x8 预测用于高清，这个是在 2005 年提出的预测。拉格朗日 RD 模型，决定在正确的时间选择。

## Intra-Frame Prediction Elements

帧内预测编码使用图像信息字段的相关性以压缩冗余。它基于在宏块的边界上，主要是指左边宏块、上方宏块和右方宏块来预测当前宏块。之后进行 DCT 和量化，从而达到压缩编码的目的。

在编码过程中，有时需要根据具体的算法和 RDO 模型来选择最终成本最低的预测模式。

16x16 亮度采用垂直预测(模型 0)、水平预测(模型 1)、DC 预测(模型 2)、平面预测(模型 3)。通过 16x16 宏块通常是应用到简单的场景，并且没有很多细节。因此
```
16 X 16 Luminance adopted plumb prediction (model 0), plane prediction (model 1), DC prediction (model 2) and planar prediction (model 3). The prediction models less than 4 X 4 luminance. It can comprehend that the macroblock should be plainness through using of 16X 16 macroblock for intra-frame and not have many details, So
it not necessary to support many texture prediction and then the luminance is likely to the prediction mode the only difference is the model code.

For reducing the extra information because of 4 X 4
prediction mode differences by the standard, it adopt a
method which can make intra-frame prediction
information trans into signal mode to realize the basic
information compression.
```

## The Existing Intra-Frame Prediction Algorithm Flows And Questions


