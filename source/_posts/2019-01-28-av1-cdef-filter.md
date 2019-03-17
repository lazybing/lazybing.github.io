---
layout: post
title: "AV1 解码详解(三)之CDEF"
date: 2019-01-28 06:32:04 -0800
comments: true
categories: av1
---

* list element with functor item
{:toc}

CDEF(constrained directional enhancement)约束方向增强滤波器是 AV1 里的几种滤波器之一， SPEC 中定义的该部分在 7.15 CDEF process 中。AOM 代码中在 cdef.c 相关的文件中。除此外，还可以参考 `The AV1 CONSTRAINED DIRECTIONAL ENHANCEMENT FILTER`论文，本文就是基于上面三个部分分析的结果。

<!--more-->

环路滤波器基于非线性低通滤波器，专为矢量化效率设计的。该滤波器考虑边缘方向和滤波模式，它通过确定每个 block 块的方向，然后自适应的用沿方向的滤波强度进行滤波。增强滤波目的是提高 AOM 的质量，尤其是低复杂性的配置中。  

## CDEF 介绍

CDEF 的主要目的是过滤掉编码杂音，同时保留图像的详细内容。AV1 中采用的方法是非线性空间滤波器，该滤波器的设计非常适用于矢量化，即可以使用 SIMD 操作，而其他非线性滤波器（如中值滤波器和双边滤波器）并非如此。  

CDEF 滤波器的设计基于以下观察：编码图像中杂音的数量通常与量化步长大致成比例，图像详细内容的数量是输入图像的一个属性，保留在量化过的图像中的最小的实际信息量也与量化成一定的比例。对于给定的步长，杂音的幅度要比细节的幅度小很多。 

CDEF 首先判断每个块的方向，之后沿着判断的方向自适应的滤波，并沿着判断的方向小幅度旋转 45 度，滤波强度明确表示，对模糊的高度控制。

CDEF 是基于之前提到的两个环路滤波器，结合的滤波器用在了 AV1 Codec 中。

从 SPEC 中的7.15 节可以看出，CDEF 可以理解为，输入为重建像素的当前帧数组，输出为包含了 Deringed 像素的数组 CDEF 帧。CDEF 的作用就是在侦测到的块方向上执行 DEringing， 码流中 CDEF 参数存放到每个64x64块(luma像素)中。可以将 CDEF 模块大致分为3步：

* CDEF Block 处理
* CDEF Direction 处理
* CDEF Filter 处理

## 方向查找

方块滤波后，方向查找就作用在重建像素上。因为重建像素对解码器是可获取的，因此滤波方向不需要特定的给出。查找作用在 8x8 块上，当应用到量化过后的图像时，该大小对于充分处理非直接边缘已经足够小，而对可靠地估计出方向又已经足够大了,有一个固定方向作用在8x8区域上，使得矢量化滤波更容易。

{% img /images/av1_cdef/av1_cdef_find_dir.png %}

对每个方向d，每行k的平均像素是: $ u_{d,k} = \frac{1}{N_{d,k}} \sum_{p \in P_{d,k}} x_p$ 其中：

* $x_p$ 是像素$p$的值
* $P_{d,k}$是在方向$d$上第$k$行的一组像素值
* $N_{d,k}$是相对$P_{d,k}$对应的基数，如$N_{1,0}=2, N_{1,4}=8$

`SSD`的计算公式如下：$E_{d}^2 = \sum_{k} \big[\sum_{p \in P_{d,k}} \big( x_{p} - u_{d,k}\big)^2 \big]$

将上面的两个公式整合后，结果如下：$E_{d}^2 = \sum_{p}x_{p}^2 - \sum_{k}\frac{1}{N_{d,k}} \big(\sum_{p \in P_{d,k}} x_p \big)^2$

我们可以通过计算上面公式中第二部分的最大值来寻找最佳方向 $d_{opt}$, $d_opt = max_d s_d$, 其中 $s_{d} = \sum_{k}\frac{1}{N_{d,k}} \big\(sum_{p \in P_{d,k}} x_p \big)^2$

可以用 840 乘以$S_d$来避免除以$N_{d,k}$,840 是所有$N_{d,k}$的最小公倍数。对于 8bit 数据，数据值为$[-128, 127]$，所有$840S_d$和所有的其他计算都适用于 32位 signed 整数类型。对于更高的bit，如10bit或12bit，在查找方向时，缩放像素到 8bit。

{% img /images/av1_cdef/direction_search.png %}

上图展示了一个针对 8x8 块，寻找方向的例子，寻找的算法如下。为了节省解码器的复杂度，我们假定亮度和色度方向是相关的，因此我们只寻找亮度原件的方向，该方向与色度方向相同。

{% img /images/av1_cdef/algorithm_find_direction.png %}

## 非线性低通滤波器

CDEF 使用非线性低通滤波器，去除编码杂音的同时不会模糊块的边缘。AV1 根据特定方向寻找滤波器抽头位置，同时当滤波器运用到块边界时，要防止过度模糊。使用非线性低通滤波器，在滤波像素偏差过大时，就不再对该像素过度强调。

### 定向滤波器

确认方向是为了统一特定方向上滤波器抽头，来降低振铃，同时不会模糊特定的边缘。但是单纯的定向滤波器有时无法高效的降低振铃效应，因此同时需要对像素数据使用滤波器抽头，该抽头并不是直接沿着主要方向。为了降低模糊块的风险，这些额外的抽头会被更保守的处理。因此，CDEF 定义了 primary taps 和 secondary taps。

primary taps 沿着方向 d，它的系数如上面图 4 所示。对 primary taps，对不同的 strength，会有不同的系数，对于1/3/5的strength，与2/4/6的strength，系数是不同的。secondary tpas 会形成一个十字架，是方向 d 旋转 45° 后得到，系数如图 5。

{% img /images/av1_cdef/primary_filter.png %}
{% img /images/av1_cdef/secondary_filter.png %}

2-D CDEF 滤波器公式如下：  

$y(i,j) = x(i,j) + round( \sum_{m,n} w_{d,m,n}^{(p)} f(x(m,n) -x(i, j), S^{(p)}, D) + \sum_{m,n} w_{d,m,n}^{(s)} f(x(m,n) -x(i,j), S^{(s)}, D))$  

* $S_{p}$和$S_{s}$是 primary 和 secondary 抽头的 strength。 

每个要滤波的 8x8 块，方向、strength 和 damping 参数是固定的。当处理位置(i, j)处的像素时，滤波器允许使用 x(i+m, j+m)处的像素，该像素可能超出 8x8 块的边界。如果处理像素超出了帧范围，像素会被忽略(f(d, S, D) = 0)。为最大化并行，CDEF 总是作用在输入(post-deblocking)像素 x(i,j)上，这样在滤波其他像素时，不会用的之前已经滤波王城的像素。 

### 代码实现分析

此处以 DAV1D 工程里的 CDEF 模块作为例子，主要介绍两部分，`cdef_find_dir`和`cdef_filter_block`，并把 10bit 汇编优化完成。完成后，在 pixel2 手机上测试，效率提升大概 30% 左右。  

#### 方向查找实现

DAV1D 工程里，对 CDEF 方向查找，完成了 C 代码实现和对 8bit 码流的汇编优化，对10bit优化并没有完成。  

{% codeblock lang:c cdef_find_dir.c %}

{% endcodeblock %}

#### CDEF 方向滤波

滤波主要由两步完成，

## 参考文档

1. [AV1 Bitstream and Decoding Process](https://aomediacodec.github.io/av1-spec/av1-spec.pdf)
2. [An Overview of Core Coding Tools in the AV1 Video Codec](https://jmvalin.ca/papers/AV1_tools.pdf)
3. [The AV1 Constrained Directional Enhancement Filter](http://www.mirlab.org/conference_papers/international_conference/ICASSP%202018/pdfs/0001193.pdf)
4. [The AV1 Constrained Directional Enhancement Filter](https://jmvalin.ca/misc_stuff/icassp2018_slides.pdf)

