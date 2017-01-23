---
layout: post
title: "Profiles-Tiers-Levels"
date: 2016-06-27 07:52:00 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

## Profile、Tier 和 Level 的概念

HEVC 中定义了三类 Profile: Main、Main10 和 Main Still Picture。  
Profile 指出码流中使用了哪些编码工具和算法。  

Levle 指出一些对解码端的负载和内存占用影响较大的关键参数约束。主要包括采样率、分辨率、码率的最大
值，压缩率的最小值，DPB 的容量，CPB（解码缓冲区）的大小。  

在 HEVC 的设计中，应用可以只依据最大的码率和 CPB 大小就可以区分。为了解决这个问题，有些 Level 定义了
两个 Tier——Main Tier 用于大多数应用，High Tier 用于那些最苛刻的应用。  

HEVC 标准定义了两类 Tiers(Main 和 High) 和 13 类 Levels。不同的Tiers和Levels对`maximum bit rate``maximum luma sample rate``maximum luma picture size`
`minimum compression ratio``maximum number of slices`和`maximum number of tiles`等。  


HM 中关于 ProfileTierLevel 的定义如下：  

```
namespace Profile
{
    enum Name
    {
        NONE               = 0,
        MAIN               = 1,
        MAIN10             = 2,
        MAINSTILLPICTURE   = 3,
        MAINREXT           = 4,
        HIGHTHROUGHPUTREXT = 5
    };
}

namespace Level
{
    enum Tier
    {
        MAIN = 0,
        HIGH = 1,
    };

    enum Name
    {
        NONE       = 0,
        LEVEL1     = 30,
        LEVEL2     = 60,
        LEVEL2_1   = 63,
        LEVEL3     = 90,
        LEVEL3_1   = 93,
        LEVEL4     = 120,
        LEVEL4_1   = 123,
        LEVEL5     = 150,
        LEVEL5_1   = 153,
        LEVEL5_2   = 156,
        LEVEL6     = 180,
        LEVEL6_1   = 183,
        LEVEL6_2   = 186,
        LEVEL8_5   = 255,
    };
}

class ProfileTierLevel
{
    Int            m_profileSpace;
    Level::Tier    m_tierFlag;
    Profile::Name  m_profileIdc;
    Bool           m_profileCompatibilityFlag[32];
    Level::Name    m_levelIdc;

    Bool           m_progressiveSourceFlag;
    Bool           m_interlacedSourceFlag;
    Bool           m_nonPackedConstraintFlag;
    Bool           m_frameOnlyConstraintFlag;
    UInt           m_bitDepthConstraintValue;
    ChromaFormat   m_chromaFormatConstraintValue;
    Bool           m_intraConstraintFlag;
    Bool           m_lowerBitRateConstraintFlag;
}
```




