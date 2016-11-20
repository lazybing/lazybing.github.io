---
layout: post
title: "PAR、DAR、SAR分析"
date: 2016-11-16 08:11:53 -0800
comments: true
categories: 总结积累
---
[Aspect Ratio](https://en.wikipedia.org/wiki/Aspect_ratio_(image)) 是图片的宽高比。  
<!--more-->

主要有 3 种`aspect ratio`：PAR(Pixel Aspect Ratio)、DAR(Display Aspect Ratio)、SAR(Sample Aspect Ratio)。

PAR(Pixel Aspect Ratio): 像素纵横比；  
DAR(Display Aspect Ratio):显示纵横比；  
SAR(Sample Aspect Ratio):采样纵横比；  

三者的关系为PAR x SAR = DAR 或者 PAR = DAR / SAR。  

PAR 示例如下：  

{% img left /images/PAR_DAR_SAR/220px-PAR-1to1.svg.png 1to1_PAR %}  

{% img right /images/PAR_DAR_SAR/220px-PAR-2to1.svg.png 2to1_PAR %}  

---------

DAR 示例如下：  

{% img left /images/PAR_DAR_SAR/Aspect_ratio_16_9_example3.jpg '16to9_DAR' %}  

{% img right /images/PAR_DAR_SAR/Aspect_ratio_4_3_example.jpg '4to3_DAR' %}  

---------
