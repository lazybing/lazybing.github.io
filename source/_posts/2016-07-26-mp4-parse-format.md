---
layout: post
title: "媒体文件格式分析之MP4"
date: 2016-07-26 04:31:32 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

[MP4](https://en.wikipedia.org/wiki/MPEG-4_Part_14)是由许多 Box 和 FullBox 组成的，每个 Box 是由 Header 和 Data 组成的，FullBox 是 Box 的扩展，Box 结构的基础上在 Header 中增加 8bits version 和 24bits flags。
<!--more-->

## 最小组单元 BOX

MP4 是由一些列的 box 组成，它的最小组成单元是 box。MP4 文件中的所有数据都装在 box 中，即 MP4 文件由若干个 box 组成，每个
 box 有类型和长度，可以将 box 理解为一个数据对象块。box 中可以包含另一个 box，这种 box 称为 container box。一个 MP4 文件首先会有且仅有
 一个`ftype`类型的 box,作为 MP4 格式的标志并包含关于文件的一些信息，之后会有且只有一个`moov`类型的box(Movie Box)，她是一种 container box,
 可以有多个，也可以没有，媒体数据的结构由 metadata 进行描述。  

{% img /images/MP4/mp4_box.png %}

* size：指明了 box 所占用的大小，包括 header 部分。  
* type: 表示这个 box 的类型。  
* largesize: 如果 box 很大超过 uint32 的最大数值,size 就被设置为 1,并用接下来的 largesize 来存放大小。 

一些基本概念：  

* track 表示一些 sample 的集合，对于媒体数据来说， track 表示一个视频或音频序列。  
* hint track 这个特殊的 track 并不包含媒体数据，而是包含了一些将其他数据 track 打包成流媒体的指示信息。  
* sample 对于非 hint track 来说， video  sample 即为一帧视频，或一组连续视频帧，audio sample 即为一段连续的压缩音频，统称为 sample。对于 hint track，sample 定义一个或多个流媒体包的格式。  
* sample table 指明 sample 时序和物理布局的表。  
* chunk 一个track的几个 sample 组成的单元。  

## MP4 文件整体结构

{% img /images/MP4/box.png %}

### File Type Box

`ftyp`类型会出现在 MP4 文件的开头，作为 MP4 容器格式的可表示信息。`ftyp box`内容结构如下：  

{% img /images/MP4/filetypebox.png %}

```
class FileTypeBox
extends Box('ftyp'){
unsigned int(32) major_brand;
unsigned int(32) minor_version;
unsigned int(32) compatible_brands[];
}
```

### Movie Box

`moov`里面包含了很多个 box,一般情况下 moov 会紧跟着 ftype。moov 里面包含着 MP4 文件中的 metedata。音视频相关
的基础信息。  

#### Movie Header Box

{% img /images/MP4/movie_header.png %}

```
class MovieHeader extends FullBox('mvhd', version, 0)
{
    if(version == 1)
    {
        unsinged int(64) creation_time;
        unsinged int(64) modification_time;
        unsinged int(64) timescale;
        unsinged int(64) duration;
    }else{
        unsinged int(32) creation_time;
        unsinged int(32) modification_time;
        unsinged int(32) timescale;
        unsinged int(32) duration;
    }

    template int(32) rate = 0x00010000;
    template int(16) volume = 0x0100;
    const bit(16) reserved = 0;
    const ungigned int(32)[2] reserved = 0;
    template int(32)[9] matrix = 
    { 0x0001000, 0, 0, 0, 0x0001000, 0, 0, 0, 0x40000000};
    bit(32)[6] pre_defined = 0;
    unsigned int(32) next_track_ID;
}
```

各个 Field 含义表格：  

| Field    | Type | Comment |
| :---:    | :---: | :---:  |
| box size | 4 | box 大小 |
| box type | 4 | box 类型 |
| version | 1 | box 版本 | 
| flags | 3 | flags |
| creation time | 4 | 创建时间 | 
| modification time | 4 | 修改时间 |
| time scale | 4 | 文件媒体在 1s 时间内的刻度值，可以理解为 1s 长度的时间单元数，一般情况下视频都是90000 |
| duration | 4 | 该 track 的时间长度，用 duration 和 time scale 值可以计算 track 时长 | 
| rate | 4 | 推荐播放速率 |
| volume | 2 | 与 rate 类似|
| reserved | 10 | 保留位 |
| matrix | 36 | 视频变化矩阵 | 
| pre-defined | 24 |  |
| nex track id | 4 | 下一个 track 使用过的id 号|

### Track Box

在`moov`这个box中会含有若干个track box每个track都是相对独立，track box里面会包含很多别的box，有2个很关键
`Track Header Box``Media Box`。

#### Track Header Box

{% img /images/MP4/movie_header.png %}

| Field | Type | Comment | 
| :---: | :---: | :---:  |
| box size | 4 | box大小 | 
| box type | 4 | box类型 |
| version  | 1 | box版本 |
| flags | 3 | 按位或操作结果值，预定义如下：0x000001 track_enabled,否则该track不被播放；0x000002 track_in_movie，表示该track在播放中被引用。|
| track id | 4 | id号 |
| reserved | 4 | 保留位 |
| duration | 4 | track的时间长度 |
| reserved | 8 | 保留位 |
| layer | 2 视频层，默认为0， 值小的在上层 | 
| alternate group | 2 | track 分组信息，默认为0表示该track未与其他track组有关系|
| volume | 2 |[8.8]格式，如果为音频track,1.0表示最大音量，否则为0 |
| reserved | 2 | 保留位 |
| matrix | 36 | 视频变化矩阵 |
| width | 4 | 宽 | 
| height | 4 | 高 |

### Media Box

#### Media Header Box

{% img /images/MP4/media_header_box.png %}

| Field | Type | Comment | 
| box size | 4 | box 大小|
| box type | 4 | box 类型 | 
| version | 1 | box 版本 |
| creation_time | 4 | 创建时间 |
| modification_time | 4 | 修改时间 |
| time scale | 4 | 文件媒体在1s内的刻度值 | 
| duration | 4 | 该 track 的时间长度 |
| langurage | 2 | 媒体语言码 |
| pre_defined | 2 | |

#### Handler Reference Box
 
{% img /images/MP4/media_header_box.png %}

| Field | Type | Comment | 
| box size | 4 | box 大小|
| box type | 4 | box 类型 | 
| flags | 3 |  |
| pre_defined | 4 | |
| handler_type | 4 | Video track(vide)/Audio track(soun)/Hint track(hint)a | 
| reserved | 12 | 0 |
| name | string | 字符串 tracke type name |

#### Media Informatino Box

`minf`里面包含着一系列的box，里面是track相关的特征信息。一般
情况minf包含:Media Information Header Boxes、Data Information Box(dinf)、Sample Table Box。

Media Information Header Boxes 根据类型分为 vmhd、smhd、hmhd、nmhd。  

