---
layout: post
title: "H264 Fast Mode Decision Algorithm"
date: 2021-04-25 17:04:16 -0700
comments: true
categories: x264
---

在编码器中，模式选择是耗时较多的一个模块，因此一个好的快速模式选择算法，是非常有必要的。好的快速模式选择，不仅能够降低编码资源消耗，还能保证编码质量不降低。
