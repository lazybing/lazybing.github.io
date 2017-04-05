---
layout: post
title: "FFMPEG 源码分析：avformat_find_stream_info"
date: 2016-12-25 06:18:07 -0800
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

`avformat_find_stream_info`主要是读媒体文件的包(packets)，然后从中提取出流的信息。
对于没有头部信息的文件格式尤其有用，比如`MPEG`。文件的逻辑位置不会被改变，读取出来
的包会被缓存起来供以后处理。  

<!--more-->

## 函数声明

```
int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options);
```
返回值：>=0-->OK,或出错返回AVERROR_xxx

注意，该函数并不保证能够打开所有的 codec，因此将options 设置为非NULL用于返回一些信息是非常好的行为。  

## 调用关系

<img src="/images/avformat_find_stream_info/avformat_find_stream_info.png">

