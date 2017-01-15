---
layout: post
title: "媒体文件格式分析之AVI"
date: 2016-07-24 01:04:52 -0700
comments: true
categories: 总结积累 
---

* list element with functor item
{:toc}


[AVI](https://en.wikipedia.org/wiki/Audio_Video_Interleave) 是音视频交错(Audio Video Interleaved)的缩写，它是 Microsoft 公司开发的一种符合 RIFF 文件规范的数字音频与视频文件格式。
<!--more-->

## 基本数据结构

AVI 文件中有两种类型结构:Chunks 和 Lists。

```
//Chunks
typedef struct {
    DWORD dwFourCC;
    DWORD dwSize;
    BYTE  data[dwSize];
}CHUNK;
//Lists
typedef struct{
    DWORD dwList;
    DWORD dwSize;
    DWORD dwFourCC;
    BYTE  data[dwSize - 4];
}LIST;
```

一个包含了`video`、`audio`或`subtitle`数据的`chunk`使用一个`dwFourCC`，
`dwFourCC`包含 2 个十六进制数字表示 stream number，2 个字母表示数据类型( dc 表示 video， wb 表示 audio, tx 表示 text)。
`dwFourCC`和`dwSize`在`Chunks`和`Lists`中有相同的含义。  

`dwFourCC`描述chunk 的类型（如`hdrl`表示 `header list`），`dwSize`表示该 chunk 或 list 的大小，
包含`dwSize`后的所有 byte。在 List 中，`dwSize`包含了`dwFourCC`所占有的4 bytes.  

`dwList`的值可以是`RIFF（RIFF-List`或`LIST(List)`。

## AVI 文件类型

通常来讲，有 3 种类型的 AVI 文件：  

* AVI 1.0, 最初始的 AVI 文件类型。  
* Open-DML, AVI 文件格式的扩展。1.02版本相对于1.0版本有两个提高：基本没有文件大小的限制、负载降低了33%。  
* Hybride-Files，Open-DML 文件因为兼容的原因有个额外的限制，Hybride-Files 虽然不是官方致命的文件类型，但确实是一个不错的类型。  

## AVI 文件布局
一个`dwFourCC=AVI`的`RIFF-List`称为`RIFF-AVI-List`，
一个`dwFourCC=AVIX`的`RIFF-List`称为`RIFF-AVIX-List`。  

每个 AVI 文件都有如下布局：
```
RIFF AVI    //mandatory
{RIFF AVIX} //only for Open-DML files
```

并非之受限于 uint32 的限制，文件大小的极限并非 4G,而是

*  对于 AVI 1.0: sizeof(RIFF-AVI) < 2G  
*  对于 Open-DML, sizeof(RIFF-AVI) < 1G(!!), sizeof(RIFF-AVIX) < 2G  

一般来讲，RIFF-AVI-Lists被创建的越小越好。  

### MainAVIHeader(avih)

`avih`结构定义如下：  
```
typedef struct
{
    DWORD dwMicroSecPerFrame;   //frame display rate(or 0)
    DWORD dwMaxBytesPerSec;     //max transfer rate
    DWORD dwPaddingGranularity; //pad to multiples of this size
    DWORD dwFlags               //the ever-present flags
    DWORD dwTotalFrames;        //frames in file
    DWORD dwInitialFrames;
    DWORD dwStreams;
    DWORD dwSuggestedBufferSize;

    DWORD dwWidth;
    DWORD dwHeight;

    DWORD dwReserved[4];
}MainAVIHeader;
```
* dwMicroSecPerFrame 以微妙为单位，包含了一个视频帧的持续时间。该值可以被忽略。注意，某些程序中可能会把它写成 framerate 值，因此 dwMicroSecPerFrame 并不可靠。  
* dwMaxBytesPerSec 文件中最大的数据率，该值同样的不是特别重要。  
* dwPaddingGranularity 填充的数据。  
* dwFlags `AVIF_HASINDEX`（该文件有index）、`AVIF_MUSTUSEINDEX`（）、`AVIF_ISINTERLEAVED` `AVIF_WASCAPTUREFILE` `AVIF_COPYRIGHTED` `AVIF_TRUSTCKTYPE`。  
* dwTotalFrames 包含了`RIFF-AVI list`中视频帧数。如果文件中包含`RIFF-AVIX-Lists`，它不会包含其中的视频帧。因为某些`muxer`会写一些错误的值，因此该值同样的不可靠。  
* dwInitialFrames 忽略
* dwStreams 文件中`streams`的数量。  
* dwSuggestedBufferSize 文件chunks 所需要的内存大小。同样不要高估它的可靠性。  
* dwWidth 视频的宽。  
* dwHeight 视频的高。  

### Stream Header List

针对每个`stream`都有一个`strl`，如果`strl`的数量与`MainAVIHeader::dwStreams`不同，就需要发出一个`fatal error report`。  

### Stream Header List Element(strh)

```
typedef struct{
    FOURCC fccType;
    FOURCC fccHandler;
    DWORD  dwFlags;
    WORD   wPriority;
    WORD   wLanguage;
    DWORD  dwInitialFrames;
    DWORD  dwScale;
    DWORD  dwRate;  // dwRate / dwScale == samples /second
    DWORD  dwStart;
    DWORD  dwLength;  //In units above
    DWORD  dwSuggestedBufferSize;
    DWORD  dwQuality;
    DWORD  dwSampleSize;
    RECT   rcFrame;
}AVIStreamHeader;
```

* fccType `vids`代表 video, `auds`代表 audio, `txts`代表 subtitle。  
* fccHandler   
* dwFlags `AVISF_DISABLED` `AVISF_VIDEO_PALCHANGES`  
* dwInitialFrames  
* dwRate / dwScale = samples / second(audio) or frames / second(video)  
* dwStart  
* dwLength  
* dwSuggestedBufferSize  
* dwQuality  
* dwSampleSize  

### Stream Header List Element(strf)

`strf`的结构依据媒体类型。对于 video，使用`BITMAPINFOHEADER`结构，而 audion，使用`WAVEFORMATEX`结构。  

```
typedef struct tagBITMAPINFOHEADER{
    DWORD biSize;
    LONG  biWidth;
    LONG  biHeight;
    WORD  biPlanes;
    WORD  biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG  biXPelsPerMeter;
    LONG  biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
}BITMAPINFOHEADER, *PBITMAPINFOHEADER;
```

* biSize  该结构体所需要的 byte 大小。
* biWidth 图像的宽度。如果`biCompression`是`BI_JPEG`或`BI_PNG`，`biWidth`成员相应的指解压缩后的`JPEG`或`PNG`图像文件的宽。
* biHeight 位图的高度。如果`biHeight`是正数，位图是自底向上的`DIB`,它的原点是右下角地点；。如果`biHeight`是正数，位图是自顶向下的`DIB`,它的原点是右上角地点；
如果`biHeight`是负数，`biCompression`要么是`BI_RGB`或`BI_BITFIELDS`，自顶向下的`DIB`不能被压缩。
如果`biCompression`是`BI_JPEG`或`BI_PNG`，则`biHeight`程序分别指解压缩后的`JPEG`或`PNG`图像的高。
* biPlanes 目标设备的`planes`的数量，该值必须是1。
* biBitCount 每个像素所用的 bit 数，`BITMAPINFOHEADER`的成员`biBitCount`决定了每个 pixel 所占的 bit 数、以及位图中表示颜色所能用到的最大数。该值可以是`0/1/4/8/16/24/32`。  
* biCompression 压缩的自底向上的位图的压缩类型，可以是`BI_RGB``BI_RLE8``BI_RLE4``BI_BITFIELDS``BI_JPEG``BI_PNG`.  
* biSizeImage 图像的大小，单位 byte。如果是`BI_RGB`位图，该值被设置为0。如果`biCompression`是`BI_JPEG`或`BI_PNG`，该值分别指示 JPEG 或 PNG 图像的大小。  
* biXPelsPerMeter 水平分辨率。  
* biYPelsPerMeter 垂直分辨率。  
* biClrUsed 颜色表中该位图实际使用的颜色指针。
* biClrImportant   

```
typedef struct{
    WORD  wFormatTag;
    WORD  nChannels;
    DWORD nSamplesPerSec;
    DWORD nAvgBytesPerSec;
    WORD  nBlocAlign;
    WORD  wBitsPerSample;
    WORD  cbSize;
}WAVEFORMATEX;
```
(待续...)

### Stream Header List Element(indx)

该结构请看下面的`AVI index`小结。  

### Stream Header List Element(strn)

该部分包含了`stream`的的名字。该名字只能使用标准的`ASCII`，尤其不能使用`UTF-8`。  

## AVI Indexes

### old style index

```
AVIINDEXENTRY index_entry[n]  
typedef struct{
    DWORD ckid;
    DWORD dwFlags;
    DWORD dwChunkOffset;
    DWORD dwChunkLength;
}AVIINDEXENTRY;
```

### Open-DML Index

```
typedef struct _aviindex_chunk{
    FOURCC fcc;
    DWORD  cb;
    WORD   wLongsPerEntry;
    BYTE   bIndexSubType;
    BYTE   bIndexType;
    DWORD  nEntriesInUse;
    DWORD  dwChunkId;
    DWORD  dwReserved[3];
    struct _aviindex_entry{
        DWORD adw[wLongsPerEntry];
    }aIndex[];
}AVIINDEXCHUNK;
```

### Using the Open-DML index

## The movi - Lists

`Movi-List`包含`Video``Audio``Subtitle`和`index data`。它们可以打包进`rec-List`。如：

```
LIST movi
    LIST rec
        01wb
        02wb
        03dc
    LIST rec
        01wb
        02wb
    LIST rec
        ...
        ...
        ix01
        ix02
        ...
```
其中的`chunks` ID 分别定义如下： 

*  ..wb : audio chunk  
*  ..dc : video chunk  
*  ..tx : subtitle chunk  
*  ix.. : standard index block  




