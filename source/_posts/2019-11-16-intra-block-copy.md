---
layout: post
title: "AV1(DAV1D)解码详解(九)之帧内编码帧内拷贝模式 Intra_Block_Copy"
date: 2019-11-16 00:59:55 -0800
comments: true
categories: AV1
---

* list element with functor item
{:toc}

AV1 允许它的帧内编码器在预测当前块时，反向搜索当前帧中之前已经重建的部分，该方式在某种程度上与帧间编码搜索之前的帧是类似的。
该方法对于屏幕内容的视频压缩非常有效，因为屏幕内容的视频通常会在同一帧中包含相同的文本、字符等内容。

<!--more-->

## 概述

帧内块拷贝(Intra Block Copy，简称 IntraBC)，除了传统的帧内和帧间预测模式外，IBC 模式采用当前帧中已重建帧作为预测块，可以认为 IntraBC 是当前编码图像内的运动补偿。

## 几个概念

AV1 SPEC 中关于 IntraBC 的几点。

> **allow_intrabc** equal to 1 indicates that intra block copy may be used in this frame. allow_intrabc equal to 0 indicates that intra block copy is not allowed in this frame.
> **Note:** intra block copy is only allowed in intra frames, and disables all loop filtering. force_integer_mv will be equal to 1 for intra frames, so only integer offsets are allowed in block copy mode.
> **force_integer_mv** equal to 1 specifies that motion vectors will always be integers. force_integer_mv equal to 0 specifies that motion vectors can contain fractional bits.

allow_intrabc 为1，表示该帧中可能存在 intra block copy，否则不存在。同时，intra block copy 仅仅在帧内编码图像中允许，使用了 intra block copy 的块，禁止任何的滤波。

> **use_intrabc** equal to 1 specifies that intra block copy should be used for this block. use_intrabc equal to 0 specifies that intra block copy should not be used.

use_intrabc 为 1，表示该宏块使用 intra_block_copy ，否则不使用该方法。


