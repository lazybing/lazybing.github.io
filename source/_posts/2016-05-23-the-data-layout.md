---
layout: post
title: "The data layout"
date: 2016-05-23 09:23:07 -0700
comments: true
categories: 总结积累 
---

图像的摆放布局各式各样，不同的布局用于不同的场景。简单记录一下常用的几种数据摆放格式。
<!--more-->
---
##YUV 数据
对于 YUV 图像来说，会有如下几个特性：`FOURCC` `Format` `Component Order` `Interlace/Progressive` `Packed/Planar` `Image Resolution`。

`FOURCC`包括：`UYVY` `UYNV` `Y422` `IUYV` 等等；

`Format`包括：`YUV420` `YUV422` `YUV444` `RGB444` `MONO`等等：
 
`Component Order`包括：`YUV` `YVU`。


###YUV420摆放格式

{% img [YUV420P layout] /source/images/datalayout/Yuv420.png 798 357 %}

