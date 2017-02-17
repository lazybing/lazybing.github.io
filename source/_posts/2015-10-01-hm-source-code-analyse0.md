---
layout: post
title: "HM 源码分析（一）"
date: 2015-10-01 07:48:51 -0700
commit: true
categories: HM源码分析
---

在 HM 的源码分析中，经常会用到读取 syntax 值，此时用到 `xReadCode` `xReadUvlc` `xReadSvlc` `xReadFlag` 的函数，这篇就主要分析这几个函数的源码。
<!--more-->

对 syntax 的分析，主要是由`SyntaxElementParser`完成，位于`lib\libdecoder\SyntaxElementParser.h`中。
{% codeblock lang:C++ syntaxelementparser.h %}

#define READ_CODE(length, code, name)     xReadCode ( length, code )
#define READ_UVLC(        code, name)     xReadUvlc (         code )
#define READ_SVLC(        code, name)     xReadSvlc (         code )
#define READ_FLAG(        code, name)     xReadFlag (         code )

class SyntaxElementParser
{
protected:
	TComInputBitstream * m_pcBitstream;
	
	SyntaxElementParser()
	: m_pcBitstream(NULL)
	{};

	virtual ~SyntaxElementParser();

	void xReadCode(UInt length, UInt& val);
	void xReadUvlc(UInt& val);
	void xReadSvlc(UInt& val);
	void xReadFlag(UInt& val);
public:
	void setBitstream(TComInputBitstream* p) { m_pcBitstream = p; }
	TComInputBitstream* getBitstream() { return m_pcBitstream; }
}
{% endcodeblock %}

其实读取 syntax 值的这几个函数，主要是 SPEC 中第 9 部分的代码实现。这几个函数共同调用了`Read`函数。
{% codeblock lang:C++ TcomBitStream.cpp %}

Void TcomInputBitstream::read (UInt uiNumberOfBits, UInt& ruiBits)
{
  assert( uiNumberOfBits <= 32 );

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

  /* all num_held_bits will go into retval
   *   => need to mask leftover bits from previous extractions
   *   => align retval with top of extracted word */
  /* n=5, len(H)=3: ---- -VVV, mask=0x07, shift_up=5-3=2,
   * n=9, len(H)=3: ---- -VVV, mask=0x07, shift_up=9-3=6 */
  uiNumberOfBits -= m_num_held_bits;
  retval = m_held_bits & ~(0xff << m_num_held_bits);
  retval <<= uiNumberOfBits;

  /* number of whole bytes that need to be loaded to form retval */
  /* n=32, len(H)=0, load 4bytes, shift_down=0
   * n=32, len(H)=1, load 4bytes, shift_down=1
   * n=31, len(H)=1, load 4bytes, shift_down=1+1
   * n=8,  len(H)=0, load 1byte,  shift_down=0
   * n=8,  len(H)=3, load 1byte,  shift_down=3
   * n=5,  len(H)=1, load 1byte,  shift_down=1+3
   */
  UInt aligned_word = 0;
  UInt num_bytes_to_load = (uiNumberOfBits - 1) >> 3;
  assert(m_fifo_idx + num_bytes_to_load < m_fifo->size());

  switch (num_bytes_to_load)
  {
  case 3: aligned_word  = (*m_fifo)[m_fifo_idx++] << 24;
  case 2: aligned_word |= (*m_fifo)[m_fifo_idx++] << 16;
  case 1: aligned_word |= (*m_fifo)[m_fifo_idx++] <<  8;
  case 0: aligned_word |= (*m_fifo)[m_fifo_idx++];
  }

  /* resolve remainder bits */
  UInt next_num_held_bits = (32 - uiNumberOfBits) % 8;

  /* copy required part of aligned_word into retval */
  retval |= aligned_word >> next_num_held_bits;

  /* store held bits */
  m_num_held_bits = next_num_held_bits;
  m_held_bits = aligned_word;

  ruiBits = retval;
}
{% endcodeblock %}

关于`read`函数其实主要分为两大来，一类是 numberofbits < num_held_bits，此时
只要通过简单的将 held_bits 左右移外加mark动作就能够把该syntax的值获得。如图1.
另一类则是 numberofbits > num_held_bits 时，需要重新加载新的bitstream进来，并根据 numberofbits 和 num_held_bits 差值的大小决定
加载几个 byte。  

{% img /images/HM/syntax_read.png %}

{% codeblock lang:C++ SyntaxElementParser.cpp %}
Void SyntaxElementParser::xReadCode (UInt uiLength, UInt& ruiCode)
{
  assert ( uiLength > 0 );
  m_pcBitstream->read (uiLength, ruiCode);
}

Void SyntaxElementParser::xReadUvlc( UInt& ruiVal)
{
  UInt uiVal = 0;
  UInt uiCode = 0;
  UInt uiLength;
  m_pcBitstream->read( 1, uiCode );

  if( 0 == uiCode )
  {
    uiLength = 0;

    while( ! ( uiCode & 1 ))
    {
      m_pcBitstream->read( 1, uiCode );
      uiLength++;
    }

    m_pcBitstream->read( uiLength, uiVal );

    uiVal += (1 << uiLength)-1;
  }

  ruiVal = uiVal;
}

Void SyntaxElementParser::xReadSvlc( Int& riVal)
{
  UInt uiBits = 0;
  m_pcBitstream->read( 1, uiBits );
  if( 0 == uiBits )
  {
    UInt uiLength = 0;

    while( ! ( uiBits & 1 ))
    {
      m_pcBitstream->read( 1, uiBits );
      uiLength++;
    }

    m_pcBitstream->read( uiLength, uiBits );

    uiBits += (1 << uiLength);
    riVal = ( uiBits & 1) ? -(Int)(uiBits>>1) : (Int)(uiBits>>1);
  }
  else
  {
    riVal = 0;
  }
}

Void SyntaxElementParser::xReadFlag (UInt& ruiCode)
{
  m_pcBitstream->read( 1, ruiCode );
}

{% endcodeblock %}

其中的`xReadCode``xReadFlag`很好理解，此处不在说明，`xReadUvlc`和`xReadSvlc`分别是处理0阶指数哥伦布编码中对 ue(n) he 
 se(n) 解析。该部分主要在 SPEC 的9.2 节。  

```
leadingZeroBits = -1;
for(b = 0; !b; leadingZeroBits++)
    b = read_bits(1);

codeNum = 2^leadingZeroBits -1 + read_bits(leadingZeroBits);
```

spec 中关于 ue 和 se 的计算有如下描述：  

> Depending on the descriptor, the value of a syntax element is derived as follows:
> If the syntax element is coded as ue(v), the value of the syntax element is equal to codeNum.
> Otherwise , the value of the syntax element is derived by invoking the mapping process for signed Exp-Golomb codes as specified in clause 9.2.2 with codeNum as input.

关于 UE 和 SE 中关于 bit 和 syntax value 的对应关系如下：  

{% img /images/HM/goloboencode.png %}

与`SyntaxElementParser`相对应的是`SyntaxElementWrite`，其中包含了`xWriteCode` `xWriteUvlc` `xWriteSvlc` `xWriteFlag`四个函数。此处不在分析。

