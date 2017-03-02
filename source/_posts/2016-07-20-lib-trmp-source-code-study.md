---
layout: post
title: "RTMP协议学习（中）：源码分析"
date: 2016-07-20 17:03:14 -0700
comments: true
categories: RTMP源码分析
---

* list element with functor item
{:toc}

了解了 RTMP 协议规范后，本文主要记录下 RTMPDump 源码的学习过程。
<!--more-->

### 大致流程

使用RTMP下载流媒体的主要流程包括以下几个步骤：

* InitSocket()
* RTMP_Init(Struct RTMP)
* RTMP_ParseURL
* RTMP_SetupStream
* fopen
* RTMP_Connect()
* RTMP_ConnectStream
* Download
* CleanUp:RTMP_Close(&rtmp); fclose(file); CleanupSockets();

下面逐个记录各个步骤的功能。
在了解具体步骤之前，先了解结构重要的Structure:
```
typedef struct RTMP
{
    int m_inChunkSize;
    int m_outChunkSize;
    int m_nBWCheckCounter;
    int m_nBytesIn;
    int m_nBytesInSent;
    int m_nBufferMS;
    int m_stream_id;
    int m_mediaChannel;
    uint32_t m_mediaStamp;
    uint32_t m_pauseStamp;
    int m_pausing;
    int m_nServerBW;
    int m_nClientBW;
    uint8_t m_nClientBW2;
    uint8_t m_bPlaying;
    uint8_t m_bSendEncoding;
    uint8_t m_bSendCounter;

    int m_numInvokes;
    int m_numCalls;
    RTMP_METHOD *m_methodCalls;
}
```

### InitSocket()

初始化 Socket ,代码非常简单。

```
int InitSockets()
{
#ifdef WIN32
    WORD version;
    WSADATA wsaData;

    version MAKEWORD(1, 1);       
    return (WSASTartup(version, &wsaData) == 1);
#else
    return TRUE;
#endif
}
```

### RTMP_Init(Struct RTMP)

初始化 RTMP 结构体。

```
void RTMP_Init(RTMP *r)
{
#ifdef CRYPTO
    if(!RTMP_TLS_cts)
        RTMP_TLS_Init();
#endif

    memset(r, 0, sizeof(RTMP));
    r->m_sb.sb_socket = -1;
    r->m_inChunkSize  = RTMP_DEFAULT_CHUNKSIZE;
    r->m_outChunkSize = RTMP_DEFAULT_CHUNKSIZE;
    r->m_nBufferMS    = 30000;
    r->m_nClientBW    = 2500000;
    r->m_nClientBW2   = 2;
    r->m_nServerBW    = 2500000;
    r->m_fAudioCodecs = 3191.0;
    r->m_fVideoCodecs = 252.0;
    r->Link.timeout   = 20;
    r->Link.swfAge    = 30;
}
```

### RTMP_ParseURL

URL 一般由三部分组成: 资源类型、存放资源的主机域名、资源文件名。
语法格式为([]为可选项):protocol://hostname[:port]/path/[:parameters][?query]#fragment
protocol(协议名称)、hostname(主机名)、port(端口号)、path(路径)、parameters(参数)。

RTMP_ParseURL函数定义:

```
int RTMP_ParseURL(const char *url, int *protocol, AVal *host, unsigned int *port, AVal *playpath, AVal *app);
```

从函数定义的几个参数可以看出，url 被定位为 const 型，即该参数在函数内部不可改变，而protocol、host、port、palypath、app 则是在函数内部根据url来进行解析，之后进行赋值的。

### RTMP_SetupStream

### fopen

### RTMP_Connect()

### RTMP_ConnectStream

### Download

### CleanUp:RTMP_Close(&rtmp); fclose(file); CleanupSockets();


