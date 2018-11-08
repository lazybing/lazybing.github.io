---
layout: post
title: "HEVC 分析工具"
date: 2015-11-01 00:09:29 -0800
comments: true
categories: hevc学习
---

* list element with functor item
{:toc}

HEVC SPEC 学习过程中，除了要看到官方参考代码 HM 外，还需要其他工具分析码流，有助于更好的理解 SPEC，本文就记录用到的几个工具。  
<!--more-->

## HM(C-Model)

HM(C-Model) 是官方的开源代码，它主要用于研究 SPEC 时可以用到。可能是最详细、最准确的研究 HEVC 的项目了，它不仅包含解码器 TAPPDecoder，还包含了编码器 TAppEncoder。

## Vega HEVC-Audio Video Analyzer

Vega 是我用过的最专业的 HEVC 图形化的分析工具，它是收费的，之前听公司人说，买的版权是**30万**， 惊呆了，目前也没在市面上见到过破解版的。图示如下：

{% img /images/hevc_analyse_tool/VegaAnalyzerHevc.png %}

## Video Pro Analyzer

Intel Video Pro Analyzer 是图形化的压缩视频码流分析工具，该工具支持市面上的大多数主流的编码标准：

* HEVC:(ITU-T H.265), 8/10-bit
* HEVC:RExt extension, 8/10/12-bit, 4:0:0/4:2:0/4:2:2/4:4:4
* VP9, profiles 0,1,2,3, 4:2:0/4:2:2/4::4:0/4:4:4, 8/10/12-bit
* AVC:(H.264/AVC, ISO/IEC 14496-10, MPEG-4 Part 10), up to High profile(except MBAFF support), 4:2:0, 8-bit
* MPEG2(ISO/IEC 13818-2 Part2), 4:2:0/4:2:2, 8-bit
* MP4 container support
* MKV container support
* MPEG-2 TS container support

{% img /images/hevc_analyse_tool/Intel_Video_Pro_Analyzer.png %}

从图中可以看出，该工具分析码流的 Syntax 值、视频的图像等等信息。

## Elecard HEVC Analyzer

Elecard StreamEye 是一个功能强大的软件工具，它是专业的解码视频压缩的工具。图示如下：

{% img /images/hevc_analyse_tool/Intel_Video_Pro_Analyzer.png %}

Elecard StreamEye 支持如下格式：

* Transport Stream MPEG-2
* Program Stream MPEG-2
* MP4 file container
* MKV file container
* AVI file container
* MPEG-1 Video stream
* MPEG-2 Video stream
* HEVC/H.265 Video Stream
* AVC/H.264 Video Stream

## CodecVisa

CodecVisa 是一个强大的码流分析工具，它目前支持大多数的压缩标准，H.265/HEVC、H.264/AVC、VP9/VP8、MPEG2等。图示如下：

{% img /images/hevc_analyse_tool/codec_visa.png %}

## HEVCESBrowser

[HEVC Browser](https://github.com/virinext/hevcesbrowser)是 github 上的一个开源项目，它有两种形式，一种是图形化的形式，一种是命令行的方式，它的功能稍微弱一些，只能显示 syntax 的值。如图所示：

{% img /images/hevc_analyse_tool/hevc_browser.png %}

## Gitl HEVC Analyzer

[Gitl HEVC Analyzer](https://github.com/lheric/GitlHEVCAnalyzer) 同 HEVCESBrowser 一样，是 github 上的一个开源项目，测试了一下，它只能显示出图像，但对码流的分析并不深入。如图所示：

{% img /images/hevc_analyse_tool/gitl_hevc_analyser.png %}

欢迎有 Vega 的朋友给到我，也欢迎需要工具的朋友联系我：libinglimit@gmail.com


