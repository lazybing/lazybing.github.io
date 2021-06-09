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

# 整数像素运动估计

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

{% img /images/h264_me/umhexagon.png 'H264 Motion Estimation UMHexagonS Search' %}

0. 选取合适的搜索起点。有以下几种起点的选择。

    ①  mvp: 由于还是整像素搜索，所以这里对 MVP 取整，得到的整数的 mv 后采用小菱形搜索以得到比较优秀的 mv。② 原点：即 mv 为0，即当前块的位置。
    ③  上层块 mv。④ 共同位置块 mv，取上一参考图像与当前块相同位置的块为 mv，然后取整。⑤  共同位置参考 mv 通过参考图像距离计算后得到的 mv，然后取整。

1. 小菱形搜索和中菱形搜索。

    首先对中值 MV 和(0, 0)点进行小钻石搜索，计算出每个搜索点的 SAD 值，并找出新的 MBD 搜索点。如果新的 MBD 点的 SAD 值比门限1 的值(2000)还要大，就执行 Step4，否则继续。  

    对搜索点进行中钻石搜索，来找出新的 MBD 搜索点。若 SAD 值小于门限值2(500)，停止搜索。否则继续。

2. 对称交叉搜索和六边形搜索。

    对上一步中找到的新的 MBD 搜索点，执行对称交叉搜索(半径为 7)和六边形搜索(半径为 2),计算这 20 个点的 SAD 值，并且找出本步最新的 MBD 点。
    
    如果该步找到的 MBD 点与上一步中的 MBD 点吻合，停止搜索。否则继续。

3. 非对称交叉搜索。执行非对称的交叉搜索，找到最新的 MBD 点。

4. 5x5搜索和多六边形网格搜索。执行 5x5 全搜索和多六边形网格搜索。

5. 迭代六边形搜索。设置上步中的 MBD 点作为搜索中心，执行迭代六边形搜索。

x264 中关于 UMH 算法的代码如下

{% codeblock lang:c %}

        case X264_ME_UMH:
        {
            /* Uneven-cross Multi-Hexagon-grid Search
             * as in JM, except with different early termination */

            static const uint8_t pixel_size_shift[7] = { 0, 1, 1, 2, 3, 3, 4 };

            int ucost1, ucost2;
            int cross_start = 1;

            /* refine predictors */
            ucost1 = bcost;
            DIA1_ITER( pmx, pmy ); //1. 小菱形搜索算法用于median MV, the small diamond search
            if( pmx | pmy )
                DIA1_ITER( 0, 0 ); //1. 小菱形搜索算法用于(0, 0), the small diamond search

            if( i_pixel == PIXEL_4x4 )
                goto me_hex2;

            ucost2 = bcost;
            if( (bmx | bmy) && ((bmx-pmx) | (bmy-pmy)) )
                DIA1_ITER( bmx, bmy );
            if( bcost == ucost2 )
                cross_start = 3;
            omx = bmx; omy = bmy;

            /* early termination */
#define SAD_THRESH(v) ( bcost < ( v >> pixel_size_shift[i_pixel] ) )
            if( bcost == ucost2 && SAD_THRESH(2000) )
            {
                COST_MV_X4( 0,-2, -1,-1, 1,-1, -2,0 ); //2. 中菱形搜索算法，找出新的MBD, the middle diamond search point
                COST_MV_X4( 2, 0, -1, 1, 1, 1,  0,2 ); //2. 中菱形搜索算法，找出新的MBD, the middle diamond search point
                if( bcost == ucost1 && SAD_THRESH(500) )
                    break;
                if( bcost == ucost2 )
                {
                    int range = (i_me_range>>1) | 1;
                    CROSS( 3, range, range ); //3. 对称的交叉搜索, symmetric cross search(radius 7)
                    COST_MV_X4( -1,-2, 1,-2, -2,-1, 2,-1 ); //3. 六边形搜索，octagon search(radius 2)
                    COST_MV_X4( -2, 1, 2, 1, -1, 2, 1, 2 ); //3. 六边形搜索，octagon search(radius 2)
                    if( bcost == ucost2 )
                        break;
                    cross_start = range + 2;
                }
            }

            /* adaptive search range */
            if( i_mvc )
            {
                /* range multipliers based on casual inspection of some statistics of
                 * average distance between current predictor and final mv found by ESA.
                 * these have not been tuned much by actual encoding. */
                static const uint8_t range_mul[4][4] =
                {
                    { 3, 3, 4, 4 },
                    { 3, 4, 4, 4 },
                    { 4, 4, 4, 5 },
                    { 4, 4, 5, 6 },
                };
                int mvd;
                int sad_ctx, mvd_ctx;
                int denom = 1;

                if( i_mvc == 1 )
                {
                    if( i_pixel == PIXEL_16x16 )
                        /* mvc is probably the same as mvp, so the difference isn't meaningful.
                         * but prediction usually isn't too bad, so just use medium range */
                        mvd = 25;
                    else
                        mvd = abs( m->mvp[0] - mvc[0][0] )
                            + abs( m->mvp[1] - mvc[0][1] );
                }
                else
                {
                    /* calculate the degree of agreement between predictors. */
                    /* in 16x16, mvc includes all the neighbors used to make mvp,
                     * so don't count mvp separately. */
                    denom = i_mvc - 1;
                    mvd = 0;
                    if( i_pixel != PIXEL_16x16 )
                    {
                        mvd = abs( m->mvp[0] - mvc[0][0] )
                            + abs( m->mvp[1] - mvc[0][1] );
                        denom++;
                    }
                    mvd += x264_predictor_difference( mvc, i_mvc );
                }

                sad_ctx = SAD_THRESH(1000) ? 0
                        : SAD_THRESH(2000) ? 1
                        : SAD_THRESH(4000) ? 2 : 3;
                mvd_ctx = mvd < 10*denom ? 0
                        : mvd < 20*denom ? 1
                        : mvd < 40*denom ? 2 : 3;

                i_me_range = i_me_range * range_mul[mvd_ctx][sad_ctx] >> 2;
            }

            /* FIXME if the above DIA2/OCT2/CROSS found a new mv, it has not updated omx/omy.
             * we are still centered on the same place as the DIA2. is this desirable? */
            CROSS( cross_start, i_me_range, i_me_range>>1 ); //4. 非对称交叉搜索, an uneven cross search

            COST_MV_X4( -2,-2, -2,2, 2,-2, 2,2 ); //5. 5x5 search

            /* hexagon grid */
            omx = bmx; omy = bmy;
            const uint16_t *p_cost_omvx = p_cost_mvx + omx*4;
            const uint16_t *p_cost_omvy = p_cost_mvy + omy*4;
            int i = 1;
            do
            {
                static const int8_t hex4[16][2] = { //5. 多六边形网格搜索, multi-hexagon-grid search
                    { 0,-4}, { 0, 4}, {-2,-3}, { 2,-3},
                    {-4,-2}, { 4,-2}, {-4,-1}, { 4,-1},
                    {-4, 0}, { 4, 0}, {-4, 1}, { 4, 1},
                    {-4, 2}, { 4, 2}, {-2, 3}, { 2, 3},
                };

                if( 4*i > X264_MIN4( mv_x_max-omx, omx-mv_x_min,
                                     mv_y_max-omy, omy-mv_y_min ) )
                {
                    for( int j = 0; j < 16; j++ )
                    {
                        int mx = omx + hex4[j][0]*i;
                        int my = omy + hex4[j][1]*i;
                        if( CHECK_MVRANGE(mx, my) )
                            COST_MV( mx, my );
                    }
                }
                else
                {
                    int dir = 0;
                    pixel *pix_base = p_fref_w + omx + (omy-4*i)*stride;
                    int dy = i*stride;
#define SADS(k,x0,y0,x1,y1,x2,y2,x3,y3)\
                    h->pixf.fpelcmp_x4[i_pixel]( p_fenc,\
                            pix_base x0*i+(y0-2*k+4)*dy,\
                            pix_base x1*i+(y1-2*k+4)*dy,\
                            pix_base x2*i+(y2-2*k+4)*dy,\
                            pix_base x3*i+(y3-2*k+4)*dy,\
                            stride, costs+4*k );\
                    pix_base += 2*dy;
#define ADD_MVCOST(k,x,y) costs[k] += p_cost_omvx[x*4*i] + p_cost_omvy[y*4*i]
#define MIN_MV(k,x,y)     COPY2_IF_LT( bcost, costs[k], dir, x*16+(y&15) )
                    SADS( 0, +0,-4, +0,+4, -2,-3, +2,-3 );
                    SADS( 1, -4,-2, +4,-2, -4,-1, +4,-1 );
                    SADS( 2, -4,+0, +4,+0, -4,+1, +4,+1 );
                    SADS( 3, -4,+2, +4,+2, -2,+3, +2,+3 );
                    ADD_MVCOST(  0, 0,-4 );
                    ADD_MVCOST(  1, 0, 4 );
                    ADD_MVCOST(  2,-2,-3 );
                    ADD_MVCOST(  3, 2,-3 );
                    ADD_MVCOST(  4,-4,-2 );
                    ADD_MVCOST(  5, 4,-2 );
                    ADD_MVCOST(  6,-4,-1 );
                    ADD_MVCOST(  7, 4,-1 );
                    ADD_MVCOST(  8,-4, 0 );
                    ADD_MVCOST(  9, 4, 0 );
                    ADD_MVCOST( 10,-4, 1 );
                    ADD_MVCOST( 11, 4, 1 );
                    ADD_MVCOST( 12,-4, 2 );
                    ADD_MVCOST( 13, 4, 2 );
                    ADD_MVCOST( 14,-2, 3 );
                    ADD_MVCOST( 15, 2, 3 );
                    MIN_MV(  0, 0,-4 );
                    MIN_MV(  1, 0, 4 );
                    MIN_MV(  2,-2,-3 );
                    MIN_MV(  3, 2,-3 );
                    MIN_MV(  4,-4,-2 );
                    MIN_MV(  5, 4,-2 );
                    MIN_MV(  6,-4,-1 );
                    MIN_MV(  7, 4,-1 );
                    MIN_MV(  8,-4, 0 );
                    MIN_MV(  9, 4, 0 );
                    MIN_MV( 10,-4, 1 );
                    MIN_MV( 11, 4, 1 );
                    MIN_MV( 12,-4, 2 );
                    MIN_MV( 13, 4, 2 );
                    MIN_MV( 14,-2, 3 );
                    MIN_MV( 15, 2, 3 );
#undef SADS
#undef ADD_MVCOST
#undef MIN_MV
                    if( dir )
                    {
                        bmx = omx + i*(dir>>4);
                        bmy = omy + i*((dir<<28)>>28);
                    }
                }
            } while( ++i <= i_me_range>>2 );
            if( bmy <= mv_y_max && bmy >= mv_y_min && bmx <= mv_x_max && bmx >= mv_x_min )
                goto me_hex2;   //6. iterative hexagon search
            break;
        }
{% endcodeblock %}

### UMH 优化思路(The Proposed Algorithm For UMH)

由于视频帧间具有时间相关性，大多数视频序列，当前宏块的方向与上一帧中相同位置宏块的方向高度相关。这意味着连续帧间，运动矢量有高度一致性。因此，当前宏块的运动方向可以通过之前帧对应坐标的方向来预测。基于运动方向预测，不同形状的搜索模式应用到 UMH 搜索模式。目标就是提升估计的运行时间，同时获得相同的质量。

方向可以通过运动矢量的角度来度量，可以使用如下公式：arcsin(-y / sqrt(x^2 + y^2)) * 180 / π 。

下面提出的算法使用上一帧中相同坐标块的运动矢量动态设置搜索非对称搜索模式的搜索长度，决定多六边形网格搜索的四分之一模式。同时，它根据上一步的方向来设计迭代六边形搜索模式。

#### Search Range Decision for Uneven Cross Pattern

在大多数视频序列中，水平方向上的运动要比垂直方向上的运动更加剧烈。正如上面提到的非对称交叉搜索中，水平方向上的长度是垂直方向上的长度的两倍。

在某些特殊的视频序列中，垂直方向上的运动比水平方向上的运动更加剧烈。因此我们可以动态的设置非对称交叉搜索模式的长度，来确保运动估计的质量。

基于连续帧的相关性，我们可以使用上一帧中相同坐标块的 MV（pmv）来预测当前块的的运动矢量，并且设置非对称交叉搜索模式的长度。如下：

```
if (pmv.dx > 2 * pmv.dy)
    PATTERN_SEARCH(CROSS1, 21, 1) //an uneven cross search: search length in vertical direction is 15 and in horizontal direction is 7.
else if (pmv.dy > 2 * pmv.dx)
    PATTERN_SEARCH(CROSS2, 21, 1) //an uneven cross search: search length in vertical direction is 7 and in horizontal direction is 15.
else
    PATTERN_SEARCH(CROSS3, 21, 1) //an uneven cross search: search length in vertical direction is the same as in horizontal direction.
```

#### Optimize for Multi-hexagon-grid Search

多六边形网格搜索包括两部分：5x5 搜索和多六边形网格搜索。

大多数真实世界的视频序列都有中心偏移运动矢量分布。有超过 80% 的运动矢量在 5x5 区域的预测内，而有 70% 的运动矢量在 3x3 区域的预测内。尽管 5x5 的区域，比 3x3 的区域有更高(10%)的预测概率,但是搜索点的数量是它的 3 倍之多。因此我们选择 3x3 搜索而不是 5x5 搜索。

第二部分是多六边形网格搜索，它有 64 个点需要检查。在此步骤中，我们根据当前宏块的运动方向预测，设计了 4 种模式，它有 20 个搜索点需要检查，这回极大的降低计算复杂度。算法描述如下：  

{% img /images/h264_me/multi_hexagon_grid.png 'H264 Motion Estimation UMHexagonS Search' %}

计算 pmv(x, y)的角度α：

a) 如果 α = 0-90，寻找 20 个搜索点，如图3(b),并找到新的 MBD，之后处理第 6 步  
b) 如果 α = 90-180，寻找 20 个搜索点，如图3(c),并找到新的 MBD，之后处理第 6 步  
c) 如果 α = 180-270，寻找 20 个搜索点，如图3(d),并找到新的 MBD，之后处理第 6 步  
d) 如果 α = -90-0，寻找 20 个搜索点，如图3(e),并找到新的 MBD，之后处理第 6 步  

#### Optimize for Iterative Hexagon Search

第六步是迭代六边形搜索模式，设置第五步中的 MBD 点作为搜索中心，最开始有 7 个点需要检查。然后在搜索过程中，六边形搜索不断前进，中心移动到六个端点中的任何一个。每次总是有三个新的点出现，而其他三个点是重复的。该算法根据前一步的方向设计新的六边形图案，避免了重复搜索冗余点。对第 6 步的优化过程如下：  

{% img /images/h264_me/iterative_hexagon.png 'H264 Motion Estimation UMHexagonS Search' %}

步骤6-1：

图4(a) 所示的六边形位于步骤 5 的 MBD 点的中心。如果在本步骤中找到的 MBD 点仍然与在上一步中找到的 MBD 点一致，则转至步骤6-3；否则计算上一步方向的角度，进行下一步处理。

a) 如果 α = 0-90,如图4(b)所示，搜索四个点；并寻找新的 MBD 点并执行步骤 6-2。  
b) 如果 α = 90-180,如图4(c)所示，搜索四个点；并寻找新的 MBD 点并执行步骤 6-2。  
a) 如果 α = 180-270,如图4(d)所示，搜索四个点；并寻找新的 MBD 点并执行步骤 6-2。  
a) 如果 α = -90-0,如图4(e)所示，搜索四个点；并寻找新的 MBD 点并执行步骤 6-2。  

步骤6-2：

以上一步搜索的 MBD 点为中心，形成一个新的六边形。检查三个新的候选点，再次确定 MBD 点。如果 MBD 仍然与上一步中发现的 MBD 点重合，则转至步骤6-3；否则，如果 4 所示重复此步骤。

步骤6-3：

将搜索模式从六边形切换到小尺寸的六边形搜索。将检查基于角度评估的两个候选点。先的 MBD 点是运动矢量的最终解。  

图 4(f) 显示了该方法的一个例子。

# 分数像素运动估计

## 亚像素搜索算法

当整数像素搜索算法优化完毕后，亚像素搜索算法的时间占比就会提升，此时对亚像素搜索算法的优化，就不能忽视了。

<H.264 标准>中规定，运动估计为1/4像素精度，因此在 H.264 编码和解码的过程中，需要将画面中的像素进行插值——简单地说就是把原先的 1 个像素点拓展成 4x4 一共 16 个点。

下图显示了  H.264 编码和解码过程中像素插值情况。可以看出原先的 G 点的右下方通过插值的方式产生了 a、b、c、d 等一共 16 个点。  

    {% img /images/h264_me/Interpolation_of_luma_half-pel.PNG 'H264 Motion Estimation UMHexagonS Search' %}    

如图所示，1/4 像素内插一般分成两成：1. 半像素内插。这一步通过 6 抽头滤波器获得 5 个半像素点。2. 线性内插。这一步通过简单的线性内插获得剩余的 1/4 像素点。   

    {% img /images/h264_me/Interpolation_of_luma_quanter-pel.PNG 'H264 Motion Estimation UMHexagonS Search' %}   


图中半像素内插点为 b、m、h、s、j五个点。半像素内插方法是对整像素点进行 6 抽头滤波得到，滤波器的权重为(1/32, -5/32, 5/8, 5/8, -5/32, 1/32)。例如 b 的计算公式为： `b = round((E - 5F + 20G + 20H - 5I + J)/32)`。  

剩下几个半像素点的计算关系如下：

```
m: 由 B、D、H、N、S、U计算  
h：由A、C、G、M、R、T计算  
s：由K、L、M、N、P、Q计算  
j：由cc、dd、h、m、ee、ff计算。 
需要注意j点的运算量比较大，因为cc、dd、ee、ff都需要通过半像素内插方法进行计算。
```
在获得半像素点之后，就可以通过简单的线性内插获得 1/4 像素内插点了。1/4 像素内插的方式如下图所示。例如图中 a 点的计算公式如下： `A = round((G + b) / 2)`

在这里有一点需要注意： 位于 4 个角的 e、g、p、r 四个点并不是通过j 点计算的，而是通过b、h、s、m四个半像素点计算的。


