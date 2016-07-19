---
layout: post
title: "RTMP 协议规范"
date: 2016-07-17 08:17:38 -0700
comments: true
categories: 源码分析
---

[RTMP](https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol)(Real Time Messaging Protocol) 即实时消息传输协议，它是 Adobe 公司开发的，并且提供了官方的[文档](https://www.adobe.com/devnet/rtmp.html)。Adobe 公司提供的RTMP协议是基于可靠传输协议(如TCP)，提供双向的信息多元化服务,其目的是在两个通信节点间传输带有时间信息的音视频并发流。其实现会针对不同的消息种类分配不同的优先级，当传输能力有限时，这就会影响流传输的排队顺序。
<!--more-->

### 1. 几个概念
* Payload:
* Packet:
* Port:
* Transport address:
* Message stream:
* Message stream ID:
* Chunk:
* Chunk stream:
* Chunk stream ID:
* Multiplexing:
* DeMultimplexing:
* Remote Procedure Call(RPC):
* Metadata:
* Application Instance:
* Action Message Format(AMF):


