---
layout: post
title: "H.264 Rate Control Algorithm"
date: 2021-06-22 06:49:35 -0700
comments: true
categories: x264
---
* list element with functor item
{:toc}

码率控制是 H.264 编码器中非常重要的一个模块。X264 的码率控制算法大致分为帧级码率控制、宏块级码率控制。帧级码率控制算法比如：VBV 调整。宏块级别码率控制比如：MBTree 算法。

<!--more-->

# 基础知识

编码所需的 bits 与实际编码的复杂度和量化参数有关，复杂度越复杂，量化参数越小，所需 bits 越少。复杂度用运动补偿后残差的 SATD 表示。

qscale = 0.85 * 2^((qp - 12)/6.0)   (1)   
qp = 12 + 6 * log2(qscale / 0.85)   (2)  

x264 中的代码如下：

{% codeblock lang:c %}
static inline float qp2scale(float qp)
{
    return 0.85 * powf(2.0f, (qp - (12.0f + QP_BD_OFFSET)) / 6.0f);
}

static inline float qscale2qp(float qscale)
{
    return (12.0f + QP_BD_OFFSET) + 6.0f * log2f(qscale / 0.85f);
}
{% endcodeblock %}

# VBV Algorithm

视频缓冲检测器(VBV, Video Buffer Verifer)是 MPEG 视频缓冲模型，可以确保码率不会超过某个最大值。VBV Buffer Size 通常设置为 maximum rate 的两倍;如果客户端缓存比较小，设置 bufsize 等于 maxrate;如果想要限制码流的码率，设置 buffersize 为 maximum rate 的一半或更小。

参考文档:  
[What are CBR, VBV and CPB](https://codesequoia.wordpress.com/2010/04/19/what-are-cbr-vbv-and-cpb/)    
[The Hypothetical Reference Decoder(HRD)](https://www.youtube.com/watch?v=Mn8v1ojV80M)

# MB-Tree Algorithm

## Macroblock-Tree 的高层概述

MB-tree 算法的目的是预测信息量，该信息量表示每个宏块对未来帧的贡献。该信息允许MB-tree基于其贡献，加权每个树的质量宏块。为此，MB-tree的工作方向与预测方向相反，将信息从将来的帧传播回要编码的当前帧。

为此，MB-tree 需要知道多种信息，或者至少近似的信息量。首先，它必须知道即将分析的未来帧的帧类型。其次，它必须知道这些帧的运动向量。第三，它必须知道每个步骤要传播多少信息量，这会根据帧内和帧间消耗来计算。接下来描述的lookahead会说明如何获取这些信息。

## x264 lookahead

x264 有个复杂的lookahead模块，该模块设计用来，在真正的编码模块分析之前，预测帧的编码消耗。它用这些预测信息来做很多的决定，比如自适应的B帧的位置、显示加权预测、以及缓冲区受阻的码率控制的比特分配。因为性能的原因，它的操作是对一半分辨率进行的，并且仅仅计算SATD残差，并不做量化和重建。

lookahead的核心是`x264_slicetype_frame_cost`函数，它会被重复的调用来计算p0/p1/b的帧代价。p0是被分析帧的前向预测帧，p1是被分析帧的后向预测帧，b是被分析的帧。如果p1等于b，则分析的帧是P帧。如果p0等于b，则分析的帧是I帧。因为`x264_slicetype_frame_cost`可能会在算法中被重复调用很多次，每次调用的结果都要保存下来以备未来使用。

`x264_slicetype_frame_cost`针对每个宏块调用`x264_slicetype_mb_cost`。因为帧只有一半的分辨率，每个宏块是`8x8`的，而不是`16x16`的。`x264_slicetype_mb_cost`对每个参考帧执行向量搜索。向量搜索是典型的六边形运动搜索。

对于B帧，它还会检查一些可能的双向模式：一个模式类似于264的时间方向，零向量；一个模式使用运动矢量结果来自list0和list1运动搜索。`x264_slicetype_mb_cost`同样计算合适的帧内代价。所有的这些代价被保存下来，用于将来使用。这对于MB-tree非常重要，它需要这些信息用于计算。

这些分析的结果主要用于Viterbi算法中自适应B帧的放置。Viterbi 算法的输出不仅仅在下一帧的类型判断时使用到，而且在后面N帧的类型判断中会用到，其中N是lookahead的大小。该计划实际上是一个队列：it changes over time as frames are pulled from one end and encoded using the specified frame types, frames are added to the other end as new frames enter the encoder, and the plan is recalculated. 该计划的存在对于宏块树非常重要：它意味着很多需要知道未来帧帧类型的算法，有个可信赖的精准预测。即使GOP的结构是变化的。

结果，MB-tree知道未来N帧的帧类型，即近似的运动矢量和模式决策以及帧内/帧间模式代价。这样的计算成本接近于零，因为这些数据在做其他任务时，在编码器内部已经计算完了。即使这样，相对于总的编码时间，lookahead的计算消耗也是成本很低的。


## MacroBlock-Tree Algorithm (MB-Tree 算法)

对于每一帧，我们在所有宏块上执行 propagate step，MacroBlock-Tree 操作的 propagate step 如下：

1. 对于当前宏块，读取下面变量的值：
* intra_cost: 该宏块的帧内模式的预测 SATD 代价。
* inter_cost: 该宏块的帧间模式的预测 SATD 代价。如果该值比 intra_cost 大，设置其为 intra_cost。
* propatate_in: 该宏块的 propagate_cost。因为没有任何信息，执行 propagate 的第一帧，它的 propagate_cost 值为 0。
2. 计算要执行 propagate 的当前宏块对其参考帧的宏块的信息的分数，称为 propagate_fraction。计算方法为 1 - intra_cost / inter_cost。例如，如果 inter_cost 是 intra_cost 的 80%，我们说该宏块有 20% 的信息来自于它的参考帧。
3. 和当前宏块有关的所有信息总和大约为 intra_cost + propagate_cost（自身信息和提供给后续帧的信息），使用这个总和乘以继承率 propagate fraction, 可以得到来继承自参考帧的信息量 propagate amount。
4. 将 propagate_amount 划分给参考帧中相关的宏块，由于当前宏块在参考帧中运动搜索得到的补偿区域可能涉及多个宏块，即参考帧中的多个宏块都参与了当前宏块的运动补偿，所以我们根据参考帧宏块参与补偿的部分尺寸大小来分配 propagate amount。特别的，对于 B 帧，我们把 propatate amount 先平分给两个参考帧，再进一步分配给参考帧中的宏块。参考帧中的宏块最终被分到的 propagate amount 加起来就是它的 propagate cost。
5. 从前向预测的最后一帧向前一直计算到当前帧，可以得到当前帧中每个宏块对后续 n 帧的 propagate_cost，最后根据当前帧每个宏块的 propatate_cost，计算相应的偏移系数 qp_offset，所使用的公式如下：

MacroblockQP = -strength * log2((intra_cost + propagate_cost) / intra_cost)。

其中强度系数 strength 为常量，对于未被参考的宏块而言，propagate_cost = 0, qp_offset = 0。

X264 源码中实现MB-Tree 的函数为 macroblock_tree，其中调用了如下三个函数来实现上述步骤：

1. slicetype_frame_cost():计算宏块的帧内代价和帧间代价。
2. macroblock_tree_propagate():计算当前宏块的遗传代价。
3. macroblock_tree_finish():计算量化参数偏移系数。

参考文档：  
[A novel macroblock-tree algorithm for high-performance optimization of.pdf]()


