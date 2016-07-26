---
layout: post
title: "媒体文件格式分析之MP4"
date: 2016-07-26 04:31:32 -0700
comments: true
categories: 总结积累
---

[MP4](https://en.wikipedia.org/wiki/MPEG-4_Part_14)是由许多 Box 和 FullBox 组成的，每个 Box 是由 Header 和 Data 组成的，FullBox 是 Box 的扩展，Box 结构的基础上在 Header 中增加 8bits version 和 24bits flags。
<!--more-->

