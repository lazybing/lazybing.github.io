---
layout: post
title: "x26源码解析之码流控制"
date: 2017-07-15 07:19:27 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

本文主要记录 X264 中使用到的码流控制。  

<!--more-->

码率控制是指视频编码中决定输出码率的过程。首先介绍一下 X264 中使用到的与码率控制相关的几个概念：  

* CQP(Constant QP),恒定QP（Quantization Parameter）,追求量化失真的恒定，瞬时码率会随场景
复杂度而波动，该模式基本被淘汰(被 CRF 取代)，只有用"-pq 0"来进行无损编码还有价值。  

* CRF(Constant Rate Factor),恒定质量因子，与恒定 QP 类似，但追求主观感知到的质量恒定，瞬时码率也
会随场景复杂度波动。对于快速运动或细节丰富的场景会适当增大量化失真（因为人眼不易注意到），反之
对于静止或平坦区域则减少量化失真。  

* ABR(Average Bitrate),平均码率，追求整个文件的码率平均达到指定值（对于流媒体有何特殊之处？）。
瞬时码率也会随着场景复杂度波动，但最终要受平均值的约束。 

* CBR(Constant Bitrate),恒定码率。前面几个模式都属于可变码率（瞬时码率在波动），即VBR（Variable Bitrate）；
恒定码率与之相对，即码率保持不变。  

x264 并没有直接提供 CBR 这种模式，但可以通过在 VBR 模式的基础上做进一步限制来达到恒定码率的目标。
CRF 和 ABR 模式都能通过`--vbv-maxrate` `--vbv-bufsize`来限制码率波动。  

关于这几个概念的参考如下：  

1.[Waht are CBR,VBV and CPB?](https://codesequoia.wordpress.com/2010/04/19/what-are-cbr-vbv-and-cpb/)  
2.[FFmpeg and H.264 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264)  
3.[CRF Guide(Constant Rate Factor in X264 and X265)](http://slhck.info/video/2017/02/24/crf-guide.html)  
4.[MeGUI/x264 setting](https://en.wikibooks.org/wiki/MeGUI/x264_Settings)  


