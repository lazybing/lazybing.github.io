---
layout: post
title: "HM源码分析（一）：HEVC编码结构"
date: 2015-09-04 09:57:17 -0700
comments: true
categories: HM源码分析
---

本文主要记录了 HEVC 的编码时的分层处理架构和编码完成后码流的语法结构两个方面的学习。
<!--more-->

## 编码分层处理架构
GOP(Group Of Pictures,GOP):若干时间连续的图像构成视频序列，视频序列分割成的图像组就为 GOP。GOP 分为封闭式 GOP 和 开放式 GOP,其中封闭式 GOP 其第一帧为 IDR, GOP内的图像不会参考到其他 GOP 内图像;开放式 GOP 只有第一个 GOP 内的第一帧才是 IDR，后续的 GOP 中的第一个帧内编码图像为 non-IDR，会参考前一个 GOP 中的已编码图像做参考图像。

{% img /images/HM/gop_type.png %}

Slice,每个 GOP 又被划分为多个 Slice 片，每个片由一个或多个片段(Slice Segment, SS) 组成。

CTU(Coding Tree Unit, CTU):每个 CTU 包括一个亮度树形编码块(Coding Tree Block, CTB) 和两个色差树形编码块。

一个 SS 在编码时，先被分割为相同大小的 CTU ，每个CTU 按照四叉树分割方式被划分为不同类型的编码单元(Coding Unit, CU)。

{% img /images/HM/slice_cu.png %}

## 码流的语法架构
VPS(Video Parameter Set):视频参数集，主要用于传输视频分级信息，包含多个子层和操作点共享的语法元素、会话所需要的有关操作的关键信息（档次/级别等）、其他不属于 SPS 的操作点特性信息（如HRD）。

SPS(Sequence Parameter Set):序列参数集，主要包含一个 CVS 中所有编码图像的共享编码参数。如图像格式信息（采样格式/图像分辨率/量化深度/Crop信息）、编码参数信息（编码块/变换块的尺寸等）、与参考图像相关的信息、可视话可用性信息(VUI)等。

PPS(Picture Parameter Set):图像参数集。主要包括编码工具的可用性标志、量化过程相关的句法元素、Tile 相关句法元素、去方块滤波相关句法元素、片头中的控制信息。

{% img /images/HM/vps_sps_pps.png %}

由上图可看出，SPS 会根据 parse 出来的`VPS index`来引用 VPS 的信息，同样的 PPS 会根据 parse 出来的`SPS index`来引用 PPS 的信息。当 SPS 中包含有 VPS 的信息时，使用 SPS 的信息，VPS内的信息失效，同样的当 PPS 中含有 SPS 的信息时，使用 PPS 中的信息，SPS 中的信息失效。

参考内容：[新一代高效视频编码H.265/HEVC:原理、标准与实现](https://www.amazon.cn/%E6%96%B0%E4%B8%80%E4%BB%A3%E9%AB%98%E6%95%88%E8%A7%86%E9%A2%91%E7%BC%96%E7%A0%81H-265-HEVC-%E5%8E%9F%E7%90%86-%E6%A0%87%E5%87%86%E4%B8%8E%E5%AE%9E%E7%8E%B0-%E4%B8%87%E5%B8%85/dp/B00QXIN7B2/ref=sr_1_1?s=books&ie=UTF8&qid=1473127274&sr=1-1&keywords=%E6%96%B0%E4%B8%80%E4%BB%A3%E9%AB%98%E6%95%88%E8%A7%86%E9%A2%91%E7%BC%96%E7%A0%81h.265+hevc+%E5%8E%9F%E7%90%86+%E6%A0%87%E5%87%86%E4%B8%8E%E5%AE%9E%E7%8E%B0)第三章编码结构。

[HM](https://hevc.hhi.fraunhofer.de/)中关于`VPS` `SPS` `PPS`编码结构的介绍主要在`lib\tlibcommon\TComSlice.h`内，稍后会对它们进行详细分析。

