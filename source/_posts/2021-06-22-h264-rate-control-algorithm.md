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


