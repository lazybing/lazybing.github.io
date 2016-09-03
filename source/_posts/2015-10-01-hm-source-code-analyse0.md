---
layout: post
title: "HM 源码分析(一）"
date: 2015-10-01 07:48:51 -0700
commit: true
categories: HM源码分析
---

在HM的源码分析中，经常会用到读取 syntax 值，此时用到 `xReadCode` `xReadUvlc` `xReadSvlc` `xReadFlag` 的函数，这篇就主要分析这几个函数的源码。

<!--more--!>
其实读取 syntax 值的这几个函数，主要是spce 中第9 部分的代码实现。这几个函数共同调用了 Read 函数。
```
  m_numBitsRead += uiNumberOfBits;

  /* NB, bits are extracted from the MSB of each byte. */
  UInt retval = 0;
  if (uiNumberOfBits <= m_num_held_bits)
  {
    /* n=1, len(H)=7:   -VHH HHHH, shift_down=6, mask=0xfe
     * n=3, len(H)=7:   -VVV HHHH, shift_down=4, mask=0xf8
     */
    retval = m_held_bits >> (m_num_held_bits - uiNumberOfBits);
    retval &= ~(0xff << uiNumberOfBits);
    m_num_held_bits -= uiNumberOfBits;
    ruiBits = retval;
    return;
  }

```
