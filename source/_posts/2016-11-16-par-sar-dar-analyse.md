---
layout: post
title: "HEVC SPEC学习之PAR、DAR、SAR"
date: 2016-11-16 08:11:53 -0800
comments: true
categories: hevc
---
[Aspect Ratio](https://en.wikipedia.org/wiki/Aspect_ratio_(image)) 是图片的宽高比。  
<!--more-->

主要有 3 种`aspect ratio`：PAR(Pixel Aspect Ratio)、DAR(Display Aspect Ratio)、SAR(Sample Aspect Ratio)。

PAR(Pixel Aspect Ratio): 像素纵横比；  
DAR(Display Aspect Ratio):显示纵横比；  
SAR(Sample Aspect Ratio):采样纵横比；  

三者的关系为PAR x SAR = DAR 或者 PAR = DAR / SAR。  

## SAR(Sample Aspect Ration)采样纵横比

HEVC SPEC 中关于 SAR 语法元素的描述如下：  

| vui_parameters(){ | Descriptor |
| :---: | :----: |
| aspect_ratio_info_present_flag | u(1) |
| if(aspect_ratio_info_present_flag){ | |
| aspect_ratio_idc | u(8) |
| if(aspect_ratio_idc == EXTENDED_SRA){ | |
| sar_width | u(16) |
| sar_height | u(16) |
| } | |
| } | |

上面提到的 SAR 语法元素的语义如下：  

* aspect_ratio_info_present_flag 值为 1，指定`aspect_ratio_idc`在码流中存在；否则该语法元素不存在。  
* aspect_ratio_idc 指定亮度采样的`SAR`的值。下面的表格展示它的含义。当`aspect_ratio_idc`值为 255，表明`EXTENDED_SRA`时，`SAR`的值
等于`sar_width:sar_height`。当`aspect_ratio_idc`语法不存在时，该值可以被认为是 0。`aspect_ratio_idc`的范围是`17-254`时，未使用，并且不该出现在码流中，此时解码器可以指定为 0。  
* sar_width 表示`SAR`的水平大小。  
* sar_height 表示`SAR`的竖直大小。  
`sar_width`和`sar_height`等于0、或`aspect_ratio_idc`等于0时，SPEC 未定义它的行为。  

| asepct_ratio_idc | Sample aspect ratio | Examples of use(informative) |
| :---: | :----: |
| 0 | Unspecified | |
| 1 | 1:1("square") | 7680x4320 16:9 frame without horizontal overscan |
| 2 | 12:11 | 720x576 4:3 frame without horizontal overscan |
| 3 | 10:11 | 720x480 4:3 frame without horizontal overscan |
| 4 | 16:11 | 720x576 16:9 frame without horizontal overscan |
| ... | ... | ... |
| 16 | 2:1 | 960x1080 16:9 frame without horizontal overscan | 
| 17...254 | Reserved | |
| 255 | EXTENDED_SAR | |

## PAR(Pixel Aspect Ratio)

PAR 示例如下：  

{% img /images/PAR_DAR_SAR/220px-PAR-1to1.svg.png '1to1_PAR' %}  

{% img /images/PAR_DAR_SAR/220px-PAR-2to1.svg.png '2to1_PAR' %}  

## DAR(Display Aspect Ratio)

DAR 示例如下：  

{% img /images/PAR_DAR_SAR/Aspect_ratio_16_9_example3.jpg '16to9_DAR' %}  

{% img /images/PAR_DAR_SAR/Aspect_ratio_4_3_example.jpg '4to3_DAR' %}  

## 参考资料  
1. [Advanced Aspect Ratios - PAR, DAR and SAR](https://www.animemusicvideos.org/guides/avtech3/theory-videoaspectratios.html)  
2. [Understanding Aspect Ratios (DAR and PAR)](http://forum.mediacoderhq.com/viewtopic.php?f=17&t=8197)  
3. [PAR, SAR, and DAR: Making Sense of Standard Definition (SD) video pixels](https://bavc.org/blog/par-sar-and-dar-making-sense-standard-definition-sd-video-pixels)  

