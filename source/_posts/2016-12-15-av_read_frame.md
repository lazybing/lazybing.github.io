---
layout: post
title: "FFMPEG 源码分析：av_read_frame"
date: 2016-12-15 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

`av_read_frame`函数实现的功能为利用给定的`AVCodec`结构初始化`AVCodecContext`结构。  

<!--more-->

