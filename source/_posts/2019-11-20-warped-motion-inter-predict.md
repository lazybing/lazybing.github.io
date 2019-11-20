---
layout: post
title: "AV1(DAV1D)解码详解(十二)之帧间编码Warped Motion"
date: 2019-11-20 15:09:25 -0800
comments: true
categories: AV1
---

* list element with functor item
{:toc}

Warped motion 模型在 AV1 中是通过两个仿射预测模型完成的，全局和局部的 warped 运动补偿。在真实世界中，物体除了简单的平移运动外，还有淡入、淡出、旋转、视角运动、不规则运动等，对于这种运动，使用放射预测能很好地提高编码性能。  

<!--more-->

##概述



