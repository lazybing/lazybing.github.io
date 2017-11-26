---
layout: post
title: "HEVC SPEC学习之Profiles-Tiers-Levels"
date: 2016-06-27 07:52:00 -0700
comments: true
categories: hevc学习
---

* list element with functor item
{:toc}

## Profile、Tier 和 Level 的概念

HEVC 中定义了三类 Profile: Main、Main10 和 Main Still Picture。  
Profile 指出码流中使用了哪些编码工具和算法。  

<!--more-->

Levle 指出一些对解码端的负载和内存占用影响较大的关键参数约束。主要包括采样率、分辨率、码率的最大
值，压缩率的最小值，DPB 的容量，CPB（解码缓冲区）的大小。  

在 HEVC 的设计中，应用可以只依据最大的码率和 CPB 大小就可以区分。为了解决这个问题，有些 Level 定义了
两个 Tier——Main Tier 用于大多数应用，High Tier 用于那些最苛刻的应用。  

HEVC 标准定义了两类 Tiers(Main 和 High) 和 13 类 Levels。不同的Tiers和Levels对`maximum bit rate``maximum luma sample rate``maximum luma picture size`
`minimum compression ratio``maximum number of slices`和`maximum number of tiles`等。  

## HEVC SPEC 中 Profile Tier Level 语法

| profle_tier_level(profilePresentFlag, maxNumSubLayersMinus1){ | Descriptor |
| :---: | :---: |
| if(profilePresentFlag){ | |
| general_profile_space | u(2) |
| general_tier_flag | u(1) |
| general_profile_idc | u(5) |
| for(j = 0; j < 32; j++) |  |
| general_profile_compatibility_flag[i] | u(1) |
| general_progressive_source_flag | u(1) |
| general_interlaced_source_flag | u(1) |
| ... | |
| general_level_idc | u(8) |
| ... | |

* general_profile_idc 当`general_profile_space`等于 0，该值表明了`profile`的标准，它的值必须是`Annex A`中包含的值，其他值未定义，保留。  
* general_level_idc 表明该视频流遵守的 level 值，它是在`Annex A`中定义的。码流中不应包含`Annex A`中未定义的值。  

> 注意，`general_level_idc`值越大，表示更高的 level。同一个`CVS`中，码流中`VPS`指定的最大 level 可能大于`SPS`指定的最大 level。

## HM 中 Profile Tier Level 实现

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


