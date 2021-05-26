---
layout: post
title: "H264 Motion Estimation Algorithm"
date: 2021-05-17 07:54:51 -0700
comments: true
categories: x264
---

* list element with functor item
{:toc}

运动估计是在参考帧中为当前编码的宏块寻找最佳匹配快，找到最佳匹配块后，运动估计会输出是运动矢量。

<!--more-->

运动估计的下一步是运动补偿(Motion Compensation)，即从当前块中减去匹配块得到残差块。在整个编码过程中，运动估计耗时占了整个编码过程的60%-80%不等，因此，对运动估计的优化是实现视频实时应用的关键。

H264 中运动估计的过程分为两步：1. 整数像素精度的估计。2. 分数像素级精度的估计。其中整数像素级的运动估计包括两类算法：全搜索算法、快速搜索算法(DIA/HEX/UMH)。

几个运动估计中用到的缩写：  

* MV: 运动矢量。被用来表示一个宏块基于该宏块中的另一个图像的位置。  
* MVP:预测运动矢量。  
* MVD：两个运动矢量的差值。  
* SATD(Sum of Absolute Transformed Difference):即 hadamard 变换后再绝对值求和。  
* SSD(Sum of Squared Difference) = SSE(Sum of Squared Error) 即差值的平方和。  
* MAD(Mean Absolute Difference) = MAE(Mean Absolute Error) 即平均绝对差值。  
* MSD(Mean Squared Difference) = MSE(Mean Squared Error) 即平均平方误差。  

## 钻石搜索算法(Diamond Search Algorithm)

钻石搜索算法有两种搜索模式： 大钻石搜索算法(LDSP)和小钻石搜索算法(SDSP)。大钻石搜索算法有 9 个搜索点，小钻石搜索算法有 5 个搜索点。

钻石搜索的步骤是：先使用 LDSP 进行搜索，直到最佳匹配点位于大菱形的中心位置；之后使用小菱形搜索，直至最佳匹配点位于小菱形的中心位置。

* LDSP:

1. 从中心搜索位置开始，设置步长 S = 2
2. 使用钻石搜索点图案搜索 8 个位置像素(X, Y), 以使(|x| + |Y| = S) 围绕位置 (0, 0)
3. 从搜索到的 9 个地点中选择，其中一个地点的费用最低
4. 如果在搜索窗口的中心找到了最小重量，请转到 SDSP 步骤
5. 如果在除中心以为的 8 个位置之一中找到最小重量，则将新的原点设置为此位置
6. 重复 LDSP

* SDSP：

1. 设置新的搜索原点
2. 将新步长设置为 S = S / 2
3. 重复搜索过程以找到重量最轻的位置
4. 选择权重最小的位置作为运动矢量权重最小的运动矢量位置。

{% img /images/h264_me/diamond_search.png 'H264 Motion Estimation Diamond Search' %}

上图可以看出，LDSP 又可分为两种模式，LDSP(1) 中的两个菱形，有 4 个重合点；LDSP(2) 中的两个菱形，有 6 个重合点。不重复计算这些点，可以节省运算复杂度。

SDSP 中, 4 个菱形的角距离中心点距离相等，因此 SDSP(1) 和 SDSP(2) 可以看出是一种模式。两个临近的搜索菱形，有 2 个重合点，不重复计算这些点，同样可以节省运算复杂度。

x264 中只采用了钻石搜索里的小钻石搜索算法, 搜索半径为 1。 具体代码实现如下:

{% codeblock lang:c %}
//diamond search, radius 1
bcost <<= 4
int i = i_me_range;

do
{
    COST_MV_X4_DIR(0, -1, 0, 1, -1, 0, 1, 0, costs);
    COPY1_IF_LT(bcost, (costs[0] << 4) + 1);
    COPY1_IF_LT(bcost, (costs[1] << 4) + 3);
    COPY1_IF_LT(bcost, (costs[2] << 4) + 4);
    COPY1_IF_LT(bcost, (costs[3] << 4) + 12);
    if (!(bcost&15))
        break;
    bmx -= (bcost << 28) >> 30;
    bmy -= (bcost << 30) >> 30;
    bcost &= ~15;
}while(--i &&CHECK_MVRANGE(bmx, bmy));
bcost >> 4;
{% endcodeblock %}

注意：这段代码写的比较 trick，先把 bcost 左移四位，留出的最后四位，每一位都代表一个搜索点，初始化时，默认菱形中心点为最佳匹配点。若菱形周边点 cost 更小，就将该点作为中心点继续进行菱形搜索，直到最佳匹配点确为中心点，跳出循环。

这段代码的速度优化空间，正如上面分析的那样，可以避开两个相邻菱形的搜索重叠搜索点。

## 六边形搜索算法(Hexagon Search Algorithm)

所谓的六边形搜索算法，不止包括六边形搜索(搜索半径为 2)，还有小菱形搜索和正方形搜索(搜索半径为 1)两种。

{% img /images/h264_me/Hexagon_Search_Algorithm.png 'H264 Motion Estimation Hexagon Search' %}

六边形搜索算法采用 1 个大模板(六边形模板)和 2 个小模板（小菱形模板和小正方形模板），具体步骤如下：

1. 以搜索起点为中心，采用上图中左边的六边形模板进行搜索。计算区域中心及周围 6 个点处的匹配误差并比较，如最小 MBD 点位于模板中心点，则转至步骤 2；否则以上一次的 MBD 点作为中心点，以六边形模板为模板进行反复搜索。

2. 以上一次的 MBD 点为中心点，采用小菱形模板搜索和小正方形模板搜索，计算各点的匹配误差，找到 MBD点, 即为最优匹配点。

从上图中的六边形搜索可以看出，两个临近的六边形，有三个重叠搜索点，因此，可以通过减少重复计算，来提升搜索性能。事实上，x264 中已经采用了这种优化方法。

{% codeblock lang:c %}
/* equivalent to the above, but eliminates duplicate candidates */

/* hexagon */
COST_MV_X3_DIR( -2,0, -1, 2,  1, 2, costs   );
COST_MV_X3_DIR(  2,0,  1,-2, -1,-2, costs+4 ); /* +4 for 16-byte alignment */
bcost <<= 3;
COPY1_IF_LT( bcost, (costs[0]<<3)+2 );
COPY1_IF_LT( bcost, (costs[1]<<3)+3 );
COPY1_IF_LT( bcost, (costs[2]<<3)+4 );
COPY1_IF_LT( bcost, (costs[4]<<3)+5 );
COPY1_IF_LT( bcost, (costs[5]<<3)+6 );
COPY1_IF_LT( bcost, (costs[6]<<3)+7 );

if( bcost&7 )
{
    int dir = (bcost&7)-2;
    bmx += hex2[dir+1][0];
    bmy += hex2[dir+1][1];

    /* half hexagon, not overlapping the previous iteration */
    for( int i = (i_me_range>>1) - 1; i > 0 && CHECK_MVRANGE(bmx, bmy); i-- )
    {
        COST_MV_X3_DIR( hex2[dir+0][0], hex2[dir+0][1],
                    hex2[dir+1][0], hex2[dir+1][1],
                    hex2[dir+2][0], hex2[dir+2][1],
                    costs );
        bcost &= ~7;
        COPY1_IF_LT( bcost, (costs[0]<<3)+1 );
        COPY1_IF_LT( bcost, (costs[1]<<3)+2 );
        COPY1_IF_LT( bcost, (costs[2]<<3)+3 );
        if( !(bcost&7) )
            break;
        dir += (bcost&7)-2;
        dir = mod6m1[dir+1];
        bmx += hex2[dir+1][0];
        bmy += hex2[dir+1][1];
    }
}
bcost >>= 3;

/* square refine */
bcost <<= 4;
COST_MV_X4_DIR(  0,-1,  0,1, -1,0, 1,0, costs );
COPY1_IF_LT( bcost, (costs[0]<<4)+1 );
COPY1_IF_LT( bcost, (costs[1]<<4)+2 );
COPY1_IF_LT( bcost, (costs[2]<<4)+3 );
COPY1_IF_LT( bcost, (costs[3]<<4)+4 );
COST_MV_X4_DIR( -1,-1, -1,1, 1,-1, 1,1, costs );
COPY1_IF_LT( bcost, (costs[0]<<4)+5 );
COPY1_IF_LT( bcost, (costs[1]<<4)+6 );
COPY1_IF_LT( bcost, (costs[2]<<4)+7 );
COPY1_IF_LT( bcost, (costs[3]<<4)+8 );
bmx += square1[bcost&15][0];
bmy += square1[bcost&15][1];
bcost >>= 4;
{% endcodeblock %}

## 非对称交叉多层次六边形网格搜索算法(Uneven Multi-hexagon-grid Search Algorithm)

运动估计中，起始搜索点和提前终止技术非常重要。

UMH 算法是基于 MV 具有时空相关性，因此可以结合上一帧和上一步中 MV 的方向和角度，来修改多层六边形的形状。

UMH 算法包含四中搜索模式:不均匀交叉搜索、多六边形网格搜索、迭代六边形搜索、菱形搜索。主要流程步骤如下:

1. 初始化搜索点。

2. 小菱形搜索和中菱形搜索。

3. 对称交叉搜索和六边形搜索。

4. 非对称交叉搜索。

5. 5x5搜索和多六边形网格搜索。

6. 迭代六边形搜索。

## 亚像素搜索算法

当整数像素搜索算法优化完毕后，亚像素搜索算法的时间占比就会提升，此时对亚像素搜索算法的优化，就不能忽视了。
