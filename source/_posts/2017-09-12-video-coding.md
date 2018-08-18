---
layout: post
title: "视频编解码算法之编码"
date: 2017-09-12 07:34:26 -0700
comments: true
categories: X264
---

* list element with functor item
{:toc}

本文记录`H.264`编解码器使用到的编码算法，包括`Exp-Golomb(哥伦布编码)`、`CAVLC(基于上下文自适应的可变长编码)`、`CABAC(基于上下文的自适应二进制算术熵编码)`。  
<!--more-->

H264 编码格式的码流包含许多编码符合，这些编码符号包括各种`syntax`、参数、预测类型、不同编码的运动矢量、转换系数等等。H264/AVC 标准
有多种编码方法：  

* Fixed length code(定长编码):符号被转换成特定长度(n bits)的二进制码字。
* Exponential-Golomb variable length code(哥伦布变长编码):符号被编码成哥伦布码字，通常越短的哥伦布码字用于表示大概率出现的符号。  
* CAVLC(基于上下文自适应的可变长编码):
* CABAC(基于上下文的自适应二进制算术熵编码):

## Exp-Golomb 哥伦布编码

## CAVLC 基于上下文自适应的可变长编码

### CAVLC 的基本原理  

熵编码是无损压缩编码方法，它生成的码流可以经解码无失真地恢复出原数据。在`H.264`中的`CAVLC`（基于上下文自适应的可变长编码）中，通过
根据已编码句法元素的情况动态调整编码中使用的码表，取得了极高的压缩比。  

`CAVLC`用于亮度和色度残差数据的编码。残差经过变换量化后的数据表现出如下特性：`4*4`块数据经过预测、变换、量化后，非零系数主要集中在
低频部分，而高频系数大部分是零；量化后的数据经过`zig-zag`扫描，DC 系数附近的非零系数值较大，而高频位置上的非零系数值大部分是+1和-1;
相邻的`4*4`块的非零系数的数目是相关的。`CAVLC`充分利用残差经过整数变换、量化后数据的特性进行压缩，进一步减少数据中的冗余信息，为`H.264`卓越的编码效率奠定了基础。  

### CAVLC 的上下文模型  

利用相邻已编码符号所提供的相关性，为索要编码的符号选择合适的上下文模型。利用合适的上下文模型，就可以大大降低符号间的冗余度。在`CAVLC`中上下文模型的选择主要体现在两个方面，非零系数
编码所需表格的选择以及拖尾系数后缀长度的更新。  

### CAVLC 的编码过程  

* 编码非零系数的数目(TotalCoeffs)以及拖尾系数的数目(TrailingOnes)  

非零系数数目的范围是从 0 到 16，拖尾细数数目的范围是从 0 到 3.如果+1/-1的个数大于 3 个，只有最后 3 个被视为脱位系数，其余的被视为普通的非零系数。
对非零系数数目和拖尾系数数目的编码是通过查表的方式，共有 4 个变长表格和 1 个定长表格可供选择。对非零系数数目和拖尾细数数目的编码是通过查表的方式，
共有 4 个变长表格和 1 个定长表格可供选择。其中的定长表格的码字是 6 个比特长，高 4 位表示非零系数的个数(TotalCoeffs)，最低两位表示拖尾系数的个数(TrailingOnes)。  

表格的选择是根据变量NC（Number Current,当前块值）的值来选择的，在求变量 NC 值得过程中，体现了基于上下文的思想。除了色度的直流系数外，其他系数类型的 NC 值是根据当前
块左边`4*4`块的非零细数数目(NA)和当前块上面`4*4`块的非零系数数目(NB)求得的。当输入的系数是色度的直流系数时，NC=-1。求 NC 的过程见表6.10，X 表示与当前快同属于一个片并可用。
选择非零系数数目和拖尾细数数目的编码表格的过程见表。  

计算 NC 的值

|上面的块(NB)|左边的块(NA)|NC|
|:----:|:----:|:----:|
|   X              |        X         | (NA+NB)/2 |
|   X              |                  |    NA     |
|   X              |                  |    NB     |
|                  |                  |    0      |

选择非零系数数目和拖尾系数数目的编码表格  

|  NC  |  表格 |
|:----:|:----:|
|0<=NC<2 | 变长表格1 |
|2<=NC<4 | 变长表格2 |
|5<=NC<8 | 变长表格3 |
|NC=-1   | 变长表格4 |
|NC>=8   | 定长表格  |

* 编码每个拖尾系数的符号  

对于每个拖尾系数(+1/-1)只需要指明其符号，其符号用一个比特表示(0 表示+, 1 表示-)。编码的顺序是按照反向扫描的顺序，从高频数据开始。  

* 编码除了拖尾系数之外的非零系数的副值(Levels)  

非零系数的幅值(Levels)的组成分为两个部分，前缀(level_prefix)和后缀(level_suffix)。`levelSuffixsSize`和`suffixLength`是编码过程
中需要使用的两个变量。后缀是长度为`LevelSuffixsSize`位的无符号整数。通常情况下变量`levelSuffixsSize`的值等于变量`suffixLenght`的值，有两种情况例外：  
1. 当前缀等于 14 时，`suffixLength`等于 0, `levelSuffixsSize`等于 4.  
2. 当前缀等于 15 时，`levelSuffixsSize`等于 12.  

变量`suffixLength`是基于上下文模式自适应更新的，`suffixLength`的更新与当前的`suffixLength`的值以及已经解码好的非零系数的值(Level)有关。`suffixLength`数值
的初始化以及更新过程如下所示：  
1. 普通情况下suffixLength 初始化为0，但是当块中有多余10个非零系数并且其中拖尾系数的数目少于3个，suffixLength初始化为1.
2. 编码在最高频率位置上的非零系数。
3. 如果当前已经解码好的非零系数值大于预先定义好的阈值，变量suffixLength加1.  

决定是否要将变量 suffixLength 的值加一的阈值如下表，第一个阈值是0，表示在第一个非零系数被编码后，suffixLength 的值总是增加 1.  

|当前suffixLength|阈值|
|:----:|:----:|
|           0          |     0    |
|           1          |     3    |
|           2          |     6    |
|           3          |     12   |
|           4          |     24   |
|           5          |     48   |
|           6          |    N/A   |

* 编码最后一个非零系数前零的数目(TotalZeros)  

`TotalZeros`指的是在最后一个非零系数前零的数目，此非零系数指的是按照正向扫描的最后一个非零系数。例如：已知一串系数`00503000100-10000`，最后一个非零系数是-1,
`TotalZeros`的值等于2+3+1+2=8。因为非零系数数目(TotalCoeffs)是已知，这就决定了`TotalZeros`可能的最大值。  

* 编码每个非零系数前零的个数(RunBefore)  

每个非零系数前零的个数(RunBefore)是按照反序来进行编码的，从最高频的非零系数开始。`RunBefore`在以下两种情况下是不需要编码的：  
1. 最后一个非零系数(在低频位置上)前零的个数。  
2. 如果没有剩余的零需要编码时，没有必要再进行 RunBefre 的编码。  

在`CAVLC`中，对每个非零系数前零的个数的编码时依赖于`ZerosLeft`的值，`ZerosLeft`表示当前非零系数左边的所有零的个数，`ZerosLeft`的初始值
等于`TotalZeros`，在每个非零系数的`RunBefore`值编码后进行更新。用这种编码方法，有助于进一步压缩编码的比特数目。例如：如果当前`ZerosLft`等于 1， 就是
只剩下一个零没有编码，下一个非零系数前零的数目只可能是0或1，编码只需要一个比特。  

### CAVLC 编码示例  

假设有一个`4x4`块数据：  

|:----:|:----:|:----:|:----:|
| 0 | 0 | -1 | 0 |
| 5 | 2 | 0  | 0 |
| 3 | 0 | 0  | 0 |
| 1 | 0 | 0  | 0 |

* `zig-zag`数据重排序：`0,0,5,3,2,-1,0,0,0,1...`
* 非零系数的数目(TotalCoeffs) = 5  
* 拖尾系数的数目(TrailingOnes) = 2  
* 最后一个非零系数前零的数目(Total_zeros) = 5  
* 变量NC = 3  

编码过程：  

| 元素 | 数值 | 编码 |  
|:----:|:----:|:----:|
| Coeff_token | TotalCoeffs=5,TraillingOnew=2|0000101|  
| Trailing_onews_sign_flag | + | 1 |  
| Trailing_onews_sign_flag | - | 0 |  
| Level(1) | 2(suffixLength=0) | 001(前缀) |  
| Level(0) | 3(suffixLength=1) | 001(前缀)0(后缀) |  
| Total_zeros | 5 | 101 |  
| Run_before(4) | Zreoleft=5,run_before=3 | 010 |  
| Run_before(3) | Zreoleft=2,run_before=0 | 1 |  
| Run_before(2) | Zreoleft=2,run_before=0 | 1 |  
| Run_before(1) | Zreoleft=2,run_before=0 | 1 |  
| Run_before(0) | Zreoleft=2,run_before=2 | 最后一个系数不需要编码 |  

`CAVLC`编码输出的码流：`0000101100010010101010111`


## CABAC 基于上下文的自适应二进制算术熵编码

## 参考文献

1. [THE H.264 ADVANCED VIDEO COMPRESSION STANDARD](http://files.cnblogs.com/files/irish/The_H.264_advanced_video_compression_standard.pdf)  
2. [指数哥伦布编码](http://blog.csdn.net/yu_yuan_1314/article/details/8969950)
3. [指数哥伦布编码](http://www.cnblogs.com/TaigaCon/p/3571651.html)
4. [H.264学习笔记6——指数哥伦布编码](http://www.cnblogs.com/DwyaneTalk/p/4035206.html)
4. [CAVLC Encoder Demo](http://wobblycucumber.blogspot.com/2013/12/cavlc-encoder-demo.html)
5. [CAVLC Encoding Tutorial](http://wobblycucumber.blogspot.com/2013/12/cavlc-encoding-tutorial.html)


