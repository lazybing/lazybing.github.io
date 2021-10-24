---
layout: post
title: "HEVC SPEC 学习之SEI——Recovery_Point"
date: 2016-11-24 18:05:50 -0800
comments: true
categories: HEVC
---

* list element with functor item
{:toc}

本文主要记录 HEVC 中的 Recovery_Point 这一类 SEI PayloadType 的介绍。`recovery point`与`H264`中`recovery point`的功能是相似的，主要作用是帮助解码器确认，在解码器凯斯随机
访问或解码器遇到序列中断的链接以后，解码过程生成能够合格显示的图像的时间。

<!--more-->

## Recovery point SEI 消息语法

| recovery_point(payloadSize) | Descriptor |
| :-----: | :-----: |
| recovery_poc_cnt | se(v) |
| exact_match_flag | u(1) |
| broken_link_flag | u(1) |

## Recovery point SEI 消息语义

当解码过程从一个解码顺序中与`recovery point sei payloadType`关联的访问单元开始时，所有此`SEI`消息指明的输出
顺序中`recovery point`以后的解码图像都是内容正确或大致正确的(即显示时不会有明显的马赛克)。有`recovery point sei payloadType`关联
的图像之前的随机访问单元生成的解码图像在内容上不一定是正确的，直到指定的`recovery point`。从与`recovery point sei payloadType`的访问
单元开始的解码过程操作可以包含对解码图像缓冲区不存在的图像的引用。  

* recovery_poc_cnt 指定输出顺序中解码图像的恢复点。如果存在图像A, 以解码顺序看它在当前图像(与当前的 SEI 消息关联的图像)的后面，并且
它的 POC 等于当前图像的 POC 加上`recovery_poc_cnt`的值，则图像A被认定为`recovery point picture`。否则，显示顺序中第一个 POC 大于当前
图像 POC 加上 `recovery_poc_cnt`值的图像被认定为`recovery point picture`。`recovery point`图像在解码顺序中不能再当前图像的前面。以显示
顺序来看，从`recovery point`图像之后的所有解码图像在内容上都是正确或基本正确的。`recovery_poc_cnt`的值应当在`-MaxPicOrderCntLsb / 2`和
`MaxPicOrderCntLsb / 2 - 1`的范围内。  

* exact_match_flag 表示在与恢复点 SEI 消息关联的访问单元处开始的解码过程输出的特定恢复点之后的解码图像，是否应该是一个与 NAL 单元流中
的前一个 IDR 访问单元位置处开始的解码过程生成的图像精确匹配的图像。值为 0 表示不一定精确匹配，为 1 表示精确匹配。  

当解码从恢复点 SEI 消息开始时，所有对不可获得的参考图像的引用应当推断为对只包含用内部宏块预测方式编码的宏块，样点值为 Y 等于 128, Cb 和 Cr 等于
128（中度灰）的图像的引用，目的是确定与`exact_match_flag`的取值的一致性。  

* broken_link_flag 表示在恢复点 SEI 消息处 NAL 单元流的链接是否出现中断。它的语义如下：
—— 如果`broken_link_flag`值为 1， 在前一个 IDR 访问单元位置处开始的解码过程生成的图像可能包含不希望的视觉假象，以致于在输出顺序中关联恢复点 SEI 消息的访问单元之后
的解码图像不可显示，直到指定的输出顺序中的恢复点。  
—— 如果`broken_link_flag`值为 0, 没有预示会出现潜在的视觉假象。  

## HM 中的 Recovery_Point

HM 源码中只是对`Recovery_Point`这一 SEI 信息做了 parse，但并没有使用解析出来的信息，可以认为 HM 中是不支持 `recovery_point`的。 其中解析的源码如下：  

{% codeblock lang:c recovery_point %}
Void SEIReader::xParseSEIRecoveryPoint(SEIRecoveryPoint& sei, UInt payloadSize, std::ostream *pDecodedMessageOutputStream)
{
  Int  iCode;
  UInt uiCode;
  output_sei_message_header(sei, pDecodedMessageOutputStream, payloadSize);

  sei_read_svlc( pDecodedMessageOutputStream, iCode,  "recovery_poc_cnt" );      sei.m_recoveryPocCnt     = iCode;
  sei_read_flag( pDecodedMessageOutputStream, uiCode, "exact_matching_flag" );   sei.m_exactMatchingFlag  = uiCode;
  sei_read_flag( pDecodedMessageOutputStream, uiCode, "broken_link_flag" );      sei.m_brokenLinkFlag     = uiCode;
  xParseByteAlign();
}
{% endcodeblock %}


