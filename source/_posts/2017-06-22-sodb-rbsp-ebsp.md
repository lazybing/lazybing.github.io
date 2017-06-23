---
layout: post
title: "SODB RBSP EBSP 的区别与联系"
date: 2017-06-22 08:48:25 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

简单总结 SODB、RBSP、EBSP、NALU 和 H.264 字节流的联系。

<!--more-->

* SODB：String of Data Bits，数据比特串，它是最原始的编码数据。
* RBSP：Raw Byte Sequence Payload, 原始字节序列载荷，它是在 SODB 的后面添加了结尾比特和若干比特`0`，以便字节对齐。
* EBSP：Encapsulate Byte Sequence Payload，扩展字节序列载荷，它是在 RBSP 基础上添加了防校验字节`0x03`后得到的。

关系大致如下：

`SODB`+`RBSP Stop bit`+`0 bits`= `RBSP` 

`RBSP part1`+`0x03`+`RBSP part2`+`0x03`+...+`RBSP partn` = `EBSP`

`NALU Header`+`EBSP`=`NALU`

`start code`+`NALU`+...+`start code`+`NALU`=`H.264 Byte Stream`

在 H264 SPEC 中，SODB 定义如下：

>3.149 string of data bits(SODB) : A sequence of some number of bits representing syntax elements present within a raw byte sequence payload prior to the raw byte sequnece payload stop bit.Within an SODB,the left-most bit is considered to be the first and most significant bit,and the right-most bit is considered to be the last and least significant bit。

要组成一个 NALU 单元，首先要有原始数据，称之为 SODB 数据。它是原始的 H264 数据编码得到的，不包含 3 字节/4 字节的起始码，即不包含`0x000001`/`0x00000001`,同样的也不包括 1 字节的 NALU 头，NALU 头部信息包含了一些基础信息，比如 NALU 类型。  

> 注意：起始码包括两种：3 字节(0x000001) 和 4 字节(0x00000001)，在 SPS、PPS 和 Access Unit 的第一个 NALU 使用 4 字节起始码，其余情况均使用 3 字节起始码。  

在 H264 SPEC 中，RBSP 定义如下：

>3.118 raw byte sequence payload(RBSP): A syntax structure containing an integer number of bytes that is encapsulated in a NAL unit.An RBSP is either empty or has the form of a string of data bits containing syntax elements followed by an RBSp stop bit and followed by zero or more subsequent bits equal to 0.
>3.119 raw byte sequence payload(RBSP) stop bit: A bit equal to 1 present within a raw byte sequence payload(RBSP) after a string of data bits.The location of the end of the string of data bits within an RBSP can be identified by searching from the end of the RBSP for the RBSP stop bit, which is the last non-zero bit in the RBSP.

在 SODB 结束处添加表示结束的 bit 1 来表示 SODB 已经结束，因此添加的 bit 1 称为`rbsp_stop_one_bit`, `RBSP`也需要字节对齐，为此需要在`rbsp_stop_one_bit`后添加若干 0 补齐。  
简单说，要在 SODB 后面追加两样东西形成 RBSP ：  

1. rbsp_stop_one_bit = 1  
2. rbsp_alignment_zero_bit(s) = 0(s)   

RBSP 的生成过程：首先，如果 SODB 的内容是空的，则 RBSP 的内容也是空的；其次，如果 SODB 的内容非空，RBSP 的第一个字节取自 SODB 的第 1 到第 8 个比特，RBSP 字节内部按照从左到右从高到低的顺序排列。
以此类推，RBSP 中的每个字节都直接取自 SODB 的相应比特。RBSP的最后一个字节包含 SODB 的最后几个比特，以及 trailing bits。其中，trailing bits 的第一个比特为 1，其余的比特为 0,保证字节对齐。最后，
在结尾添加 0x0000,即 CABAC_ZERO_WORD，从而形成 RBSP。

{% img /images/sodb_rbsp/sodb_rbsp.PNG %}

EBSP 的生成过程：NALU 数据 + 起始码就形成了Annex B 格式，起始码包括两种，0x00000001 或 0x000001。为了不让NALU的主体与起始码之间产生竞争，在对 RBSP 进行扫描时，如果遇到连续的两个`0x00`字节，则在该两个字节后面添加一个`0x03`字节。在解码的时候将该`0x03`字节去掉，也成为脱壳操作。
通过该种方式形成 EBSP，这需要将近两倍的整帧图像码流大小。为了减少存储器需求，在每个 macroblock 结束后，即检查该 macroblock 的 SODB 的起始码竞争问题，并保留 SODB 的最后两个字节的零字节个数，以便与下一个 macroblock 的 SODB 的开始字节形成连续的起始码竞争检测。对一帧图像的最后一个 macroblock，先添加结尾停止 bit，在检查起始码竞争。  

替换规则如下：  

* 0x000000 => 0x00000300  
* 0x000001 => 0x00000301  
* 0x000002 => 0x00000302  
* 0x000003 => 0x00000303  

