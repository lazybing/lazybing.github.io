---
layout: post
title: "X264源码解析之x264_deblock_init函数"
date: 2017-07-22 06:16:09 -0700
comments: true
categories: x264
---

* list eleent with functor item
{:toc}

本文主要介绍 X264 中滤波的部分,`x264_deblock_init`函数主要对`x264_deblock_function_t`结构体中的函数指针赋值。  
<!--more-->




