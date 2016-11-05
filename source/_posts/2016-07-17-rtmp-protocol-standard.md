---
layout: post
title: "RTMP 协议学习（上）: 协议规范"
date: 2016-07-17 08:17:38 -0700
comments: true
categories: RTMP源码分析
---

[RTMP](https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol)(Real Time Messaging Protocol) 即实时消息传输协议，它是 Adobe 公司开发的，并且提供了官方的[文档](https://www.adobe.com/devnet/rtmp.html)。Adobe 公司提供的RTMP协议是基于可靠传输协议(如TCP)，提供双向的信息多元化服务,其目的是在两个通信节点间传输带有时间信息的音视频并发流。其实现会针对不同的消息种类分配不同的优先级，当传输能力有限时，这就会影响流传输的排队顺序。
<!--more-->

### 1. 几个概念
* 负载(Payload): 分组中包含的数据，比如音频采样数据和视频压缩数据。
* 分组(Packet): 数据分组由固定头部和负载组成的。对于底层协议，可能需要定义分组的封装。
* 端口(Port): 用于区分不同的目标抽象，一般用整数表示，如TCP/IP中的端口号。
* 传输地址(Transport address): 网络地址和端口号的组合,用于标识一个传输层的端口。如IP地址+TCP端口号。
* 消息流(Message stream): 允许消息流动的逻辑上的通讯通道。
* 消息流ID(Message stream ID): 每隔消息都有与之关联的ID号，用于与其他消息流作区分。
* 块(Chunk): 一个消息片段。消息被放到网络上传输之前被切分成小的片段并被交错存取。分块确保跨流的所有消息按时间戳顺序被不断的传输。
* 块流(Chunk stream): 
* 块流ID(Chunk stream ID): 每个块所关联的用于区分其他块流的ID。
* 复用(Multiplexing): 将音视频数据整合到一个数据流内,使得多个音视频数据流可以同步传输.
* 解复用(DeMultimplexing): 复用的反过程,交互的音视频数据被分成原始的音频数据和视频数据。
* 远程过程调用(Remote Procedure Call(RPC)): 
* 元数据(Metadata): 数据的一个简单描述。如一部电影的电影名、时长、制作时间等等.
* 应用Instance（Application Instance): 对于服务器端的应用Instance，客户端就是通过连接该Instance来发送请求的.
* Action Message Format(AMF):

### 2.字节序、字节对齐和时间格式
所有完整的字段都是按照网络字节序被承载的。即零字节是第一个字节，bit 0 是一个字段中的最高有效位。即所谓的大端。
如无特殊说明，RTMP 中的所有字段都是字节对齐的。
```
#define ALIGN_16bit(value) (((value + 15) >> 4) << 4)
#define ALIGN_32bit(value) (((value + 31) >> 5) << 5)
#define ALIGN_64bit(value) (((value + 63) >> 6) << 6)
```
RTMP 中的时间戳用整数来表示，它是以毫秒为单位的相对时间。典型的，码流中都是从时间戳为0开始的，但这不是必须的，只要通讯双方用统一的时间即可。注意，这就要求任何跨流的同步都需要 RTMP 外的额外机制。

### 3. RTMP Chunk Stream

#### 3.1 消息格式

根据上层协议，消息格式可以被分成多个块以支持复用。消息格式应包含如下字段，这对于创建块是必须的:
1. 时间戳(TimeStamp)：消息的时间戳，占 4 个字节。
2. 长度(Length): 消息的长度，包含头部。占头部中的3 个字节。
3. 类型Id(Type Id): 
4. 消息流ID（Message Stream ID）:

#### 3.2 握手(HandShake)

RTMP 协议开始于握手，这里的握手不同于其他协议的握手，它是由 3 个固定大小的块组成，而不是带有头部的可变大小的块。
客户端和服务器端都会发送 3 个固定大小的块。客户端发送的称为 C0/C1/C2，服务器端发送的称为S0/S1/S2。

#####握手序列:

首先，握手必须是由客户端发送C0/C1开始的。
其次，客户端必须接收到服务器端发送的S1后才能发送C2, 必须接收到服务器端发送的S2后才能发送其他数据。
再次，服务器端必须等到客户端发送的C0后才能发送S0和S1,也可等到接收到C1后再发送。
同样，服务器端必须等到客户端发送的C1后才能发送S1,必须等到客户端发送的C2后才能发送其他数据。

##### C 和 S 格式：

C0 和 S0 是一个8-bit的整数字段：
C1 和 S1 是一个1536 byte 的序列，其中 4 byte 是表示时间，4 byte 全部填0，剩余部分填写其他值。
C2 和 S2 是对 C1 和 S1 的一个对等。

##### 握手框图(HandShake Diagram)

<image src="/images/RTMPProtocol/HandShake_Diagram.png">

对上面的框图进行简单说明如下：

未初始化阶段(Uninitialized):协议版本会在该阶段发送。客户端和服务器端都处于未初始化阶段。客户端在 C0 包里发送协议版本，如果服务器端支持该协议，就会发送 S0 和 S1 作为反馈，如果不支持，就会终止连接。

版本发送阶段(Version Sent): Uninitialized 阶段后，客户端和服务器端都会进入 Version Sent 阶段。客户端等待服务器端发送的 S1 包，服务器端等待客户端发送的 C1 包。一旦等到回应后，客户端会发送 C2 包、服务器端会发送 S2 包。之后进入 Ack Sent 阶段。

确认阶段(ACK Sent):客户端和服务器端分别等待 S2 和 C2.

握手结束(Handshake Done):客户端和服务器端交换消息。

### Chunking


