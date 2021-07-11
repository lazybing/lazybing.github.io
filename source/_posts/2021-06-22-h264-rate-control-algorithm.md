---
layout: post
title: "H.264 Rate Control Algorithm"
date: 2021-06-22 06:49:35 -0700
comments: true
categories: x264
---
* list element with functor item
{:toc}

码率控制是 H.264 编码器中非常重要的一个模块。码率控制主要包括两部分：码率分配(Bit Allocation)、量化参数调整(Quantitative Parameter Adjustment)。X264 的码率控制算法大致分为帧级码率控制、宏块级码率控制。帧级码率控制算法比如：VBV 调整。宏块级别码率控制比如：MBTree 算法、VAQ 感知量化算法。

<!--more-->

# 基础知识

码率控制的主要过程是：  

1. 根据前面已经编好的帧计算 SATD 值来预测当前帧的复杂度(第一帧 I 帧除外)；  
2. 计算好复杂度后，根据复杂度和线性量化控制参数(qcomp)来计算 qpscale。qpscale 会影响最终编码时所用的 qp。  
3. 根据目标码率和之前编码所用的比特数可以确定一个 rate_factor，若之前编码的比特数多与目标实际产生，则 rate_factor 减小。这个 rate_factor 是调整 qpscale 用的，还有 overflow 来对qpscale 来做溢出补偿处理来控制文件大小。    
4. 最后根据计算公式得到 qp。

参考文档：  

[x264 码率控制算法原理](https://pianshen.com/article/4198342118)

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

# 模糊复杂度估计

One Pass 编码中，由经过运动补偿后残差的 SATD 代表一帧的复杂度，SATD 是将残差做  Hadrmard 变换后再取绝对值的总和，它作为一种简单的时频交换，能在一定程度上衡量生产码流的大小。

模糊复杂度是基于已编码帧的复杂度加权得到的。使用复杂度加权，相对于使用单独一帧的复杂度，能避免 QP 的波动：  

blurred_complexity = cplxsum/cplxcount    
cplxsum[i]   = cplxsum[i - 1] * 0.5 + satd[i - 1]  
cplxcount[i] = cplxcount[i - 1] * 0.5 + 1  

{% codeblock lang:c %}
double wanted_bits, overflow = 1;

rcc->last_satd = x264_rc_analyse_slice(h);
rcc->short_term_cplxsum *= 0.5;
rcc->short_term_cplxcount *= 0.5;
rcc->short_term_cplxsum += rcc->last_satd / (CLIP_DURATION(h->fenc->f_duration) / BASE_FRAME_DURATION);
rcc->short_term_cplxcount++;

rce.text_bits = rc->last_satd;
rce.blurred_complexity = rcc->short_term_cplxsum / rcc->short_term_cplxcount;

{% endcodeblock %}

# VBV Algorithm

VBV 是一种帧级别的码率控制算法，它是这样一种机制: VBV 相当于一个容器，每编码一帧，都从容器内取走对应 bit 的数据；与此同时，往容器内以固定的速度输入 bit。每编码完一帧，根据容器内的充盈状态(上溢/下溢)，更新接下来编码参数，使得容器的充盈程都总是处于合理的范围内。  

视频缓冲检测器(VBV, Video Buffer Verifer)是 MPEG 视频缓冲模型，可以确保码率不会超过某个最大值。VBV Buffer Size 通常设置为 maximum rate 的两倍;如果客户端缓存比较小，设置 bufsize 等于 maxrate;如果想要限制码流的码率，设置 buffersize 为 maximum rate 的一半或更小。

先来看一下，x264 中关于 VBV 的几个变量定义：  
{% codeblock lang:c %}
struct x264_ratecontrol_t
{
    int b_vbv;
    int b_vbv_min_rate;

    /*VBV stuff*/
    double buffer_size;     //VBV buffer size, 容器的总容量
    int64_t buffer_fill_final;
    int64_t buffer_fill_final_min;
    double buffer_fill; //planned buffer, if all in-progress frames hit their bit budget
    doublt buffer_rate; //# of bits added to buffer_fill after each frame
    double vbv_max_rate;//# of bits added to buffer_fill per second
    predictor_t *pred;  //predict frame size from satd
    int single_frame_vbv;
    float rate_factor_max_increment; //Don't allow RF above(CRF + this value)
}
{% endcodeblock %}

X264 中，关于 VBV 的调整在 clip_qscale 中。根据是否有 lookahead，可以分为 lookahead vbv 调整和实时 VBV 调整两种。

## Lookahead vbv 调整

从 lookahead 模块可以得到未来若干帧的复杂度。vbv 算法的原理是：一样的 qscale 应用到 lookahead 中的所有帧中，检测会不会有帧使得 VBV 缓存下溢，并且 lookahead 中所有帧编码结束后，缓存填充度在一个合理的范围内，小步调整 qscale 直到满足上述要求。

{% codeblock lang:c %}
int terminate = 0;
/*Avoid an infinite loop*/
for (int iterations = 0; iterations < 1000 && terminate != 3; iterations++)
{
	double frame_q[3];
	double cur_bits = predict_size( &rcc->pred[h->sh.i_type], q, rcc->last_satd );
	double buffer_fill_cur = rcc->buffer_fill - cur_bits;
	double target_fill;
	double total_duration = 0;
	double last_duration = fenc_cpb_duration;
	frame_q[0] = h->sh.i_type == SLICE_TYPE_I ? q * h->param.rc.f_ip_factor : q;
	frame_q[1] = frame_q[0] * h->param.rc.f_pb_factor;
	frame_q[2] = frame_q[0] / h->param.rc.f_ip_factor;

	/* Loop over the planned future frames. */
	for( int j = 0; buffer_fill_cur >= 0 && buffer_fill_cur <= rcc->buffer_size; j++ )
	{
	    total_duration += last_duration;
	    buffer_fill_cur += rcc->vbv_max_rate * last_duration;
	    int i_type = h->fenc->i_planned_type[j];
	    int i_satd = h->fenc->i_planned_satd[j];
	    if( i_type == X264_TYPE_AUTO )
		break;
	    i_type = IS_X264_TYPE_I( i_type ) ? SLICE_TYPE_I : IS_X264_TYPE_B( i_type ) ? SLICE_TYPE_B : SLICE_TYPE_P;
	    cur_bits = predict_size( &rcc->pred[i_type], frame_q[i_type], i_satd );
	    buffer_fill_cur -= cur_bits;
	    last_duration = h->fenc->f_planned_cpb_duration[j];
	}
	/* Try to get to get the buffer at least 50% filled, but don't set an impossible goal. */
	target_fill = X264_MIN( rcc->buffer_fill + total_duration * rcc->vbv_max_rate * 0.5, rcc->buffer_size * 0.5 );
	if( buffer_fill_cur < target_fill )
	{
	    q *= 1.01;
	    terminate |= 1;
	    continue;
	}
	/* Try to get the buffer no more than 80% filled, but don't set an impossible goal. */
	target_fill = x264_clip3f( rcc->buffer_fill - total_duration * rcc->vbv_max_rate * 0.5, rcc->buffer_size * 0.8, rcc->buffer_size );
	if( rcc->b_vbv_min_rate && buffer_fill_cur > target_fill )
	{
	    q /= 1.01;
	    terminate |= 2;
	    continue;
	}
	break;
}
{% endcodeblock %}

## 实时 VBV 调整

如果没有 lookahead，未来帧的复杂度未知，只能根据当前帧的复杂度，控制缓存的充盈程度。算法主要流程如下：

1. 对于 P 帧和第一个 I 帧，让当前帧编码完成后，缓存区至少还有一半容量。  
2. 限制每帧大小不能超过当前缓存量的一半。  
3. 限制每帧大小至少是 buffer_rate 的一半。buffer_rate = vbv-maxrate/fps。
4. 限制 qscale 不能小于输入 qscale。

{% codeblock lang:c %}
    if( ( pict_type == SLICE_TYPE_P ||
        ( pict_type == SLICE_TYPE_I && rcc->last_non_b_pict_type == SLICE_TYPE_I ) ) &&
        rcc->buffer_fill/rcc->buffer_size < 0.5 )
    {
        q /= x264_clip3f( 2.0*rcc->buffer_fill/rcc->buffer_size, 0.5, 1.0 );
    }

    /* Now a hard threshold to make sure the frame fits in VBV.
     * This one is mostly for I-frames. */
    double bits = predict_size( &rcc->pred[h->sh.i_type], q, rcc->last_satd );
    /* For small VBVs, allow the frame to use up the entire VBV. */
    double max_fill_factor = h->param.rc.i_vbv_buffer_size >= 5*h->param.rc.i_vbv_max_bitrate / rcc->fps ? 2 : 1;
    /* For single-frame VBVs, request that the frame use up the entire VBV. */
    double min_fill_factor = rcc->single_frame_vbv ? 1 : 2;

    if( bits > rcc->buffer_fill/max_fill_factor )
    {
        double qf = x264_clip3f( rcc->buffer_fill/(max_fill_factor*bits), 0.2, 1.0 );
        q /= qf;
        bits *= qf;
    }
    if( bits < rcc->buffer_rate/min_fill_factor )
    {
        double qf = x264_clip3f( bits*min_fill_factor/rcc->buffer_rate, 0.001, 1.0 );
        q *= qf;
    }
    q = X264_MAX( q0, q );
{% endcodeblock %}

## minGOP vbv 调整

B 帧 QP 不直接被 VBV 调整，它由 P 帧加一个偏移量得到。这一步检查当前 P 帧和（编码顺序）到下一个 P 帧之前的 B 帧的复杂度。适当调低 qscale (调高码率预算)，使得本 minGOPher 过后，缓存区没有上溢。

{% codeblock lang:c %}
double bits = predict_size(&rcc->pred[h->sh.i_type], q, rcc->last_satd);
double frame_size_maximum = X264_MIN(rcc->frame_size_maximum, X264_MAX(rcc->buffer_fill, 0.001));
if (bits > frame_size_maximum)
    q *= bits / frame_size_maximum;

if (!rcc->b_vbv_min_rate)
    q = X264_MAX(q0, q);
{% endcodeblock %}

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
[A novel macroblock-tree algorithm for high-performance optimization of.pdf](https://download.csdn.net/download/To_Be_IT_1/19848868?spm=1001.2014.3001.5501)

# Adaptive Quantization Algorithm

自适应量化就是根据宏块的复杂度来调整每个宏块量化时的量化参数。自适应量化的基本原理是：根据当前宏块的复杂度 SSD，与当前帧的平均复杂度做对比，若高于平均，则分配更多的码率，即用小于当前帧 QP 值的量化步长；低于平均值则分配更少的码率，即用大于当前帧的 QP 值的量化步长。

自适应量化主要有两个参数：aq-mode（自适应量化模式）、aq-strength（自适应量化强度）。自适应量化强度决定码率偏向于低细节(SSD)部分的强度。

X264 中，自适应量化的实现在`x264_adaptive_quant_frame`中：

{% codeblock lang:c %}
/* constants chosen to result in approximately the same overall bitrate as without AQ.
 * FIXME: while they're written in 5 significant digits, they're only tuned to 2. */
float strength;
float avg_adj = 0.f;
float bias_strength = 0.f;

if( h->param.rc.i_aq_mode == X264_AQ_AUTOVARIANCE || h->param.rc.i_aq_mode == X264_AQ_AUTOVARIANCE_BIASED )
{
    float bit_depth_correction = 1.f / (1 << (2*(BIT_DEPTH-8)));
    float avg_adj_pow2 = 0.f;
    for( int mb_y = 0; mb_y < h->mb.i_mb_height; mb_y++ )
        for( int mb_x = 0; mb_x < h->mb.i_mb_width; mb_x++ )
        {
            uint32_t energy = ac_energy_mb( h, mb_x, mb_y, frame );
            float qp_adj = powf( energy * bit_depth_correction + 1, 0.125f );
            frame->f_qp_offset[mb_x + mb_y*h->mb.i_mb_stride] = qp_adj;
            avg_adj += qp_adj;
            avg_adj_pow2 += qp_adj * qp_adj;
        }
    avg_adj /= h->mb.i_mb_count;
    avg_adj_pow2 /= h->mb.i_mb_count;
    strength = h->param.rc.f_aq_strength * avg_adj;
    avg_adj = avg_adj - 0.5f * (avg_adj_pow2 - 14.f) / avg_adj;
    bias_strength = h->param.rc.f_aq_strength;
}
else
    strength = h->param.rc.f_aq_strength * 1.0397f;

for( int mb_y = 0; mb_y < h->mb.i_mb_height; mb_y++ )
    for( int mb_x = 0; mb_x < h->mb.i_mb_width; mb_x++ )
    {
        float qp_adj;
        int mb_xy = mb_x + mb_y*h->mb.i_mb_stride;
        if( h->param.rc.i_aq_mode == X264_AQ_AUTOVARIANCE_BIASED )
        {
            qp_adj = frame->f_qp_offset[mb_xy];
            qp_adj = strength * (qp_adj - avg_adj) + bias_strength * (1.f - 14.f / (qp_adj * qp_adj));
        }
        else if( h->param.rc.i_aq_mode == X264_AQ_AUTOVARIANCE )
        {
            qp_adj = frame->f_qp_offset[mb_xy];
            qp_adj = strength * (qp_adj - avg_adj);
        }
        else
        {
            uint32_t energy = ac_energy_mb( h, mb_x, mb_y, frame );
            qp_adj = strength * (x264_log2( X264_MAX(energy, 1) ) - (14.427f + 2*(BIT_DEPTH-8)));
        }
        if( quant_offsets )
            qp_adj += quant_offsets[mb_xy];
        frame->f_qp_offset[mb_xy] =
        frame->f_qp_offset_aq[mb_xy] = qp_adj;
        if( h->frames.b_have_lowres )
            frame->i_inv_qscale_factor[mb_xy] = x264_exp2fix8(qp_adj);
    }

{% endcodeblock %}


