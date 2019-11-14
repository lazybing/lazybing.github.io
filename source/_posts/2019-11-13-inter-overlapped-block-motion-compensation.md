---
layout: post
title: "AV1(DAV1D)解码详解(七)之帧间编码 OBMC"
date: 2019-11-13 08:04:43 -0800
comments: true
categories:  av1
---

* list element with functor item
{:toc}

OBMC 会使用当前块运动矢量和相邻子块运动矢量进行运动补偿，减少方块效应。OBMC 通过融合相邻块的 Motion Vector 预测，很大程度上降低当前块预测错误。

<!--more-->

## OBMC 概述

OBMC 会使用当前块运动矢量和相邻子块运动矢量进行运动补偿，减少方块效应。OBMC 通过融合相邻块的 Motion Vector 预测，很大程度上降低当前块预测错误。

## 代码

{% codeblock lang:c %}
static int obmc(Dav1dTileContext *const t,
                pixel *const dst, const ptrdiff_t dst_stride,
                const uint8_t *const b_dim, const int pl,
                const int bx4, const int by4, const int w4, const int h4)
{
    assert(!(t->bx & 1) && !(t->by & 1));
    const Dav1dFrameContext *const f = t->f;
    const refmvs *const r = &f->mvs[t->by * f->b4_stride + t->bx];
    pixel *const lap = t->scratch.lap;
    const int ss_ver = !!pl && f->cur.p.layout == DAV1D_PIXEL_LAYOUT_I420;
    const int ss_hor = !!pl && f->cur.p.layout == DAV1D_PIXEL_LAYOUT_I444;
    const int h_mul = 4 >> ss_hor, v_mul = 4 >> ss_ver;
    int res;

    if (t->by > t->ts->tiling.row_start &&
        (!pl || b_dim[0] * h_mul + b_dim[1] * v_mul >= 16))
    {
        for (int i = 0, x = 0; x < w4 && i < imin(b_dim[2], 4);) {
            // only odd blocks are considered for overlap handling, hence + 1
            const refmvs *const a_r = &r[x - f->b4_stride + 1];
            const uint8_t *const a_b_dim = 
                dav1d_block_dimensions[sbtype_to_bs[a_r->sb_type]];

            if (a_r->ref[0] > 0) {
                const int ow4 = iclip(a_b_dim[0], 2, b_dim[0]);
                const int oh4 = imin(b_dim[1], 16) >> 1;
                res = mc(t, lap, NULL, ow4 * h_mul * sizeof(pixel), ow4, oh4,
                         t->bx + x, t->by, pl, a_r->mv[0],
                         &f->refp[a_r->ref[[0] - 1], a_r->ref[0] - 1,
                         dav1d_filter_2d[t->a->filter[1][bx4 + x + 1]][t->a->filter[0][bx4 + x + 1]]);
                if (res) return res;
                f->dsp->mc.blend_h(&dst[x * h_mul], dst_stride, lap,
                                   h_mul * ow4, v_mul * oh4);
                i++;
            }
            x += imax(a_b_dim[0], 2);
        }
    }

    if (t->bx > t->ts->tiling.col_start)
    {
        for (int i = 0, y = 0; y < h4 && i < imin(b_dim[3], 4); ) {
            // only odd blocks are considered for overlap handling, hence +1
            const refmvs *const l_r = &r[(y + 1) * f->b4_stride - 1];
            const uint8_t *const l_b_dim =
                dav1d_block_dimensions[sbtype_to_bs[l_r->sb_type]];

            if (l_r->ref[0] > 0) {
                const int ow4 = imin(b_dim[0], 16) >> 1;
                const int oh4 = iclip(l_b_dim[1], 2, b_dim[1]);
                res = mc(t, lap, NULL, h_mul * ow4 * sizeof(pixel), ow4, oh4,
                         t->bx, t->by + y, pl, l_r->mv[0],
                         &f->refp[l_r->ref[0] - 1], l_r->ref[0] - 1,
                         dav1d_filter_2d[t->l.filter[1][by4 + y + 1]][t->l.filter[0][by4 + y + 1]]);
                if (res) return res;
                f->dsp->mc.blend_v(&dst[y * v_mul * PXSTRIDE(dst_stride)],
                                dst_stride, lap, h_mul * ow4, v_mul * oh4);
                i++;
            }
            y += imax(l_b_dim[1], 2);
        }
    }
    return 0;
}
{% endcodeblock %}

