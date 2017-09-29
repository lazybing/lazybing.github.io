---
layout: post
title: "视频编解码算法之编码"
date: 2017-09-12 07:34:26 -0700
comments: true
categories: X264
---

* list element with functor item
{:toc}

本文记录`H.264`编解码器使用到的编码算法，包括`Exp-Golomb(哥伦布编码)`、`CAVLC(基于上下文自适应的可变长编码)`、`CABAC(基于上下文的自适应二进制算术熵编码)`。  
<!--more-->

H264 编码格式的码流包含许多编码符合，这些编码符号包括各种`syntax`、参数、预测类型、不同编码的运动矢量、转换系数等等。H264/AVC 标准
有多种编码方法：  

* Fixed length code(定长编码):符号被转换成特定长度(n bits)的二进制码字。
* Exponential-Golomb variable length code(哥伦布变长编码):符号被编码成哥伦布码字，通常越短的哥伦布码字用于表示大概率出现的符号。  
* CAVLC(基于上下文自适应的可变长编码):
* CABAC(基于上下文的自适应二进制算术熵编码):

## Exp-Golomb 哥伦布编码



## CAVLC 基于上下文自适应的可变长编码

## CABAC 基于上下文的自适应二进制算术熵编码

## 参考文献

1. [THE H.264 ADVANCED VIDEO COMPRESSION STANDARD](http://files.cnblogs.com/files/irish/The_H.264_advanced_video_compression_standard.pdf)  
2. [指数哥伦布编码](http://blog.csdn.net/yu_yuan_1314/article/details/8969950)
3. [指数哥伦布编码](http://www.cnblogs.com/TaigaCon/p/3571651.html)
4. [H.264学习笔记6——指数哥伦布编码](http://www.cnblogs.com/DwyaneTalk/p/4035206.html)
4. [CAVLC Encoder Demo](http://wobblycucumber.blogspot.com/2013/12/cavlc-encoder-demo.html)
5. [CAVLC Encoding Tutorial](http://wobblycucumber.blogspot.com/2013/12/cavlc-encoding-tutorial.html)


