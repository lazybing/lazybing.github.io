---
layout: post
title: "SODB RBSP EBSP 的区别于联系"
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

在 H264 SPEC 中，RBSP 定义如下：
>3.118 raw byte sequence payload(RBSP): A syntax structure containing an integer number of bytes that is encapsulated in a NAL unit.An RBSP is either empty or has the form of a string of data bits containing syntax elements followed by an RBSp stop bit and followed by zero or more subsequent bits equal to 0.
>3.119 raw byte sequence payload(RBSP) stop bit: A bit equal to 1 present within a raw byte sequence payload(RBSP) after a string of data bits.The location of the end of the string of data bits within an RBSP can be identified by searching from the end of the RBSP for the RBSP stop bit, which is the last non-zero bit in the RBSP.
