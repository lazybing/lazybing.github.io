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
{% codeblock [lang:C++] syntaxelementparser.h}

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
