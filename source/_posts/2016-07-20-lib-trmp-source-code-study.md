---
layout: post
title: "RTMP协议学习（中）：源码分析"
date: 2016-07-20 17:03:14 -0700
comments: true
categories: 源码分析
---

了解了 RTMP 协议规范后，本文主要记录下 RTMPDump 源码的学习过程。
<!--more-->

### 大致流程
使用RTMP下载流媒体的主要流程包括以下几个步骤：
1. InitSocket()
2. RTMP_Init(Struct RTMP)
3. RTMP_ParseURL
4. RTMP_SetupStream
4. fopen
5. RTMP_Connect()
6. RTMP_ConnectStream
7. Download
8. CleanUp:RTMP_Close(&rtmp); fclose(file); CleanupSockets();

下面逐个记录各个步骤的功能。

### InitSocket()
### RTMP_Init(Struct RTMP)
### RTMP_ParseURL
### RTMP_SetupStream
### fopen
### RTMP_Connect()
### RTMP_ConnectStream
### Download
### CleanUp:RTMP_Close(&rtmp); fclose(file); CleanupSockets();



