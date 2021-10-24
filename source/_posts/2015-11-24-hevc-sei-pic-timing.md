---
layout: post
title: "HEVC SPEC 学习之SEI——Pic_Timing"
date: 2015-11-24 18:05:50 -0800
comments: true
categories: HEVC
---

* list element with functor item
{:toc}

本文主要记录 HEVC 中的 Picture timing 这一类 SEI PayloadType 的介绍。

<!--more-->

## Pic Timing SEI 消息语法

| pic_timing(payloadSize){ | Descriptor |
| :-----: | :-----: |
| if(frame_field_info_present_flag){| |
| pic_struct | u(4) |
| source_scan_type | u(2) |
| duplicate_flag | u(1) |
| } | |
| ... | |
| } | |

## Pic Timing SEI 消息语义

* pic_struct 指明了图像是按照帧图或场图显示；如果是作为帧图显示，当`fixed_pic_rate_within_cvs_flag`值为 1 时，可以表明帧图像在显示时会重复两次或三次，帧的刷新间隔为固定的`DpbOutputElementalInterval[n]`。
`pic_struct`的含义如下图所示。对于未列出的`pic_struct`值，作为保留值用于将来使用，一般不会出现在码流中，如果出现，解码器可以忽略它的值。  

| Value | Indicated display of picture | Restrictions | 
| :---: | :---: | :---: |
| 0   | (progressive)Frame | field_seq_flag 为 0 |
| 1   | Top Field | field_seq_flag 为 1 |
| 2   | Bottom Field | field_seq_flag 为 1 |
| 3   | Top Field, Bottom Field, in that order | field_seq_flag 为 0 |
| 4   | Bottom Field, Top Field, in that order | field_seq_flag 为 0 |
| 5   | Top Field, Bottom Field, Top Field, in that order | field_seq_flag 为 0 |
| 6   | Bottom Field, Top Field, Bottom Field, in that order | field_seq_flag 为 0 |
| 7   | Frame doubling | field_seq_flag 为 0, fixed_pic_rate_within_cvs_flag 为 1 |
| 8   | Frame tripling | field_seq_flag 为 0, fixed_pic_rate_within_cvs_flag 为 1 |
| 9   | Top Field paired with previous bottom field in that order | field_seq_flag 为 1 |
| 10  | Bottom Field paired with previous top field in that order | field_seq_flag 为 1 |
| 11  | Top Field paired with next bottom field in that order | field_seq_flag 为 1 |
| 12  | Bottom Field paired with next top field in that order | field_seq_flag 为 1 |

如果码流中存在`pic_struct`,它必须严格遵守下面的条件：
—— 同一个`CVS`中，所有图像的`pic_struct`的值等于0、7 或 8。
—— 同一个`CVS`中，所有图像的`pic_struct`的值等于1、2、9、10、11 或 12。
—— 同一个`CVS`中，所有图像的`pic_struct`的值等于3、4、5、或 6。

* source_scan_type 如果其值为 1，表明该图像的扫描类型为`progressive`；如果其值为 0,表明该图像的扫描类型为`interlace`;如果其值为 2，表明该图像的扫描类型未定义；如果是其他值，解码器可以将其值设为 2。  

关于扫描类型的描述，在`SPS`中的`profile_tier_level`中也有描述，是通过`general_progressive_souce_flag`和`general_interlaced_source_flag`两个语法元素决定的：  
1. 如果`general_progressive_souce_flag`值为0，并且`general_interlaced_source_flag`值为1，`source_scan_type`的值如果存在就该为0，如果不存在，解码器也可以将其设置为0。  
2. 如果`general_progressive_souce_flag`值为1，并且`general_interlaced_source_flag`值为0，`source_scan_type`的值如果存在就该为1，如果不存在，解码器也可以将其设置为1。  
3. 如果`general_progressive_souce_flag`值为0，并且`general_interlaced_source_flag`值为0，`source_scan_type`的值如果存在就该为2，如果不存在，解码器也可以将其设置为2。  

针对`interlaced`码流，解码器必须指定该图像是`Top`或`Bottom`，并且说明该码流是`Top First`或`Bottom`。具体实现看下面`HM`中的实现。  

## HM中的Picture_Timing  

HM 源码中对`pic_timing`这一 SEI 信息做了比较详细的描述，首先是在 Parse SEI 时获得`pic_struct`等的信息，之后会根据他的值，对`TFF`和`Field`进行赋值，当然HM中对于该值得覆盖也不是很全，只是覆盖到 1 和 2。  

{% codeblock lang:c pic_timing %}
Void SEIReader::xParseSEIPictureTiming(SEIPictureTiming& sei, UInt payloadSize, TComSPS *sps, std::ostream *pDecodedMessageOutputStream)
{
  ...
    if( vui->getFrameFieldInfoPresentFlag() )
    {
        sei_read_code( pDecodedMessageOutputStream, 4, code, "pic_struct" );             sei.m_picStruct            = code;
        sei_read_code( pDecodedMessageOutputStream, 2, code, "source_scan_type" );       sei.m_sourceScanType       = code;
        sei_read_flag( pDecodedMessageOutputStream,    code, "duplicate_flag" );         sei.m_duplicateFlag        = (code == 1);
    }
  ...
}

Bool TDecTop::xDecodeSlice(InputNALUnit &nal, Int &iSkipFrame, Int iPOCLastDisplay)
{
    ...
    Bool isField = false;
    Bool isTff = false;

    if(!m_SEIs.empty())
    {
      // Check if any new Picture Timing SEI has arrived
      SEIMessages pictureTimingSEIs = extractSeisByType (m_SEIs, SEI::PICTURE_TIMING);
      if (pictureTimingSEIs.size()>0)
      {
        SEIPictureTiming* pictureTiming = (SEIPictureTiming*) *(pictureTimingSEIs.begin());
        isField = (pictureTiming->m_picStruct == 1) || (pictureTiming->m_picStruct == 2);
        isTff =  (pictureTiming->m_picStruct == 1);
      }
    }

    //Set Field/Frame coding mode
    m_pcPic->setField(isField);
    m_pcPic->setTopField(isTff);
    ...
}
{% endcodeblock %}

