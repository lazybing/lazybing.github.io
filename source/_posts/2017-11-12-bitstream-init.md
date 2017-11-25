---
layout: post
title: "X264源码解析之X264_bitstream_init函数"
date: 2017-11-12 06:48:31 -0800
comments: true
categories: X264 
---
* list element with functor item
{:toc}

本文主要记录 X264 中对于 bitstream 的处理方法，它主要实现 SPEC 中`Annex B:Byte stream format`中的规定。
<!--more-->

## H264 SPEC Annex B

首先看一下，H264 的 SPEC 中关于 Bitstream 中的规定。  

{% codeblock lang:c AnndexB %}
byte_stream_nal_unit(NumBytesInNALunit)
{
    while(next_bits(24) != 0x000001 &&
          next_bits(32) != 0x00000001)
        leading_zero_8bits //equal to 0x00 f(8)

    if(next_bits(24) != 0x000001)
        zero_byte  //equal to 0x00 f(8)

    start_code_prefix_one_3bytes //equal to 0x000001 f(24)

    nal_unit(NumBytesInNALunit)

    while(more_data_in_byte_stream() &&
          next_bits(24) != 0x000001 &&
          next_bits(32) != 0x00000001)
        trailing_zero_8bits //equal to 0x00 f(8)
}
{% endcodeblock %}

SPEC 中定义的解码的部分，因为我们根据上面的描述，可以理出 H264 的大致解析过程：  

1. 解码过程开始时，解码器把其当前的位置初始化为字节流的起始位置。然后提取，并丢弃每一个`leading_zero_8bits`语法元素(如果存在的话)，移动当前位置至某一时刻的字节处，直到比特流的当前位置紧接的四个字节为四字节序列`0x00000001`。 
2. 当字节流里的紧接的四个字节构成四字节序列`0x00000001`，对比特流中下一个字节(为 zero_byte 语法元素)进行提取并丢弃时，字节流的当前位置设为紧接被丢弃的字节的字节位置。  
3. 提取与丢弃比特流中下一个三字节序列(为 start_code_prefix_one_3bytes)，且比特流当前位置设为此紧接被丢弃的 3 字节序列的字节的位置。  
4. NumBytesInNALunit 设为自当前字节位置起至下述条件前的位置的最后一个字节，且包括最后一个字节的编号。
a. 一个三字节序列的排列等于`0x000000`，或
b. 字一个三字节序列的排列等于`0x000001`，或 
c. 字节流的结束，由未规定的方式判决。  
5. NumBytesInNALunit 字节从比特流中移除，字节流的当前位置前移 NumBytesInNALunit 字节。这个字节序列为 `nal_unit(NumBytesInNALunit)`,并用 NAL 单元解码过程进行解码。  
6. 当字节流中的当前位置不为字节流的结尾(由未规定的方式判决)，且字节流中的下一个字节不是等于`0x000001`开始的三字节序列，也不是等于`0x00000001`开始的四字节序列。解码器提取并丢弃每一个`trailing_zero_8bits`语法元素，移动字节流中的当前位置到某一时刻的一个字节处，直到字节流里的当前位置接下来的四个字节构成四字节的序列`0x00000001`或已至字节流的结尾(由未规定的当时判决)。  

## JM 中关于 AnnexB 的源码分析

在看`X264`源码之前，让我们先看一下 JM 中关于 AnnexB 的解码的源码实现部分。  

`JM`中关于 AnnexB 部分的描述在`jm\decod\src\annexb.c`中,首先看一下其中最重要的一个函数`int GetAnnexbNALU(NALU_t *nalu)`,该函数的声明如下：  

```
/*
 * Brief: Returns the size of the NALU( bits between start codes in case of
 *        Annex B, nalu->buf and nalu->len are filled. Other field in
 *        nalu->remain uninitialized( will be taken care of by NALUtoRBSP.
 * Return: 0 if there is nothing any more to read(EOF)
 *         -1 in case of any error
 * note Side-effect: Returns length of start-code in bytes.
 * 
 * Note: GetAnnexbNALU expects start codes at byte aligned positions in the file
 */
int GetAnnexbNALU(NALU_t *nalu);
```

`GetAnnexbNALU`的定义如下：  

{% codeblock lang:c GetAnnexbNALU %}
int GetAnnexbNALU(NALU_t *nalu)
{
  int info2, info3, pos = 0;
  int StartCodeFound, rewind;
  char *Buf;
  int LeadingZero8BitsCount=0, TrailingZero8Bits=0;
    
  if ((Buf = (char*)calloc (nalu->max_size , sizeof(char))) == NULL) no_mem_exit("GetAnnexbNALU: Buf");

  //如果start_code前还有数据，丢弃start_code前leading_zero_8bits
  while(!feof(bits) && (Buf[pos++]=fgetc(bits))==0);
  
  if(feof(bits))
  {
    if(pos==0)
    return 0;
    else
    {
      printf( "GetAnnexbNALU can't read start code\n");
      free(Buf);
      return -1;
    }
  }

  if(Buf[pos-1]!=1)
  {
    printf ("GetAnnexbNALU: no Start Code at the begin of the NALU, return -1\n");
    free(Buf);
    return -1;
  }

  if(pos<3)
  {
    printf ("GetAnnexbNALU: no Start Code at the begin of the NALU, return -1\n");
    free(Buf);
    return -1;
  }
  else if(pos==3)
  {
    nalu->startcodeprefix_len = 3;
    LeadingZero8BitsCount = 0;
  }
  else
  {
    LeadingZero8BitsCount = pos-4;
    nalu->startcodeprefix_len = 4;
  }

  //the 1st byte stream NAL unit can has leading_zero_8bits, but subsequent ones are not
  //allowed to contain it since these zeros(if any) are considered trailing_zero_8bits
  //of the previous byte stream NAL unit.
  //字节流数据的第一个 NAL 单元才会有leading_zero_8bits;后面的 NALU 不会包含 leading_zero_8bits,
  //因为这些 leading_zero_8bits 会被看做前一个 NAL 单元后面的 trailing_zero_8bits
  if(!IsFirstByteStreamNALU && LeadingZero8BitsCount>0)
  {
    printf ("GetAnnexbNALU: The leading_zero_8bits syntax can only be present in the first byte stream NAL unit, return -1\n");
    free(Buf);
    return -1;
  }
  IsFirstByteStreamNALU=0;

  StartCodeFound = 0;
  info2 = 0;
  info3 = 0;

  while (!StartCodeFound)
  {
    if (feof (bits))
    {
      //Count the trailing_zero_8bits
      while(Buf[pos-2-TrailingZero8Bits]==0)
        TrailingZero8Bits++;
      nalu->len = (pos-1)-nalu->startcodeprefix_len-LeadingZero8BitsCount-TrailingZero8Bits;
      memcpy (nalu->buf, &Buf[LeadingZero8BitsCount+nalu->startcodeprefix_len], nalu->len);     
      nalu->forbidden_bit = (nalu->buf[0]>>7) & 1;
      nalu->nal_reference_idc = (nalu->buf[0]>>5) & 3;
      nalu->nal_unit_type = (nalu->buf[0]) & 0x1f;

// printf ("GetAnnexbNALU, eof case: pos %d nalu->len %d, nalu->reference_idc %d, nal_unit_type %d \n", pos, nalu->len, nalu->nal_reference_idc, nalu->nal_unit_type);

#if TRACE
  fprintf (p_trace, "\n\nLast NALU in File\n\n");
  fprintf (p_trace, "Annex B NALU w/ %s startcode, len %d, forbidden_bit %d, nal_reference_idc %d, nal_unit_type %d\n\n",
    nalu->startcodeprefix_len == 4?"long":"short", nalu->len, nalu->forbidden_bit, nalu->nal_reference_idc, nalu->nal_unit_type);
  fflush (p_trace);
#endif
      free(Buf);
      return pos-1;
    }
    //找 start_code，先找0x00000001,后找0x000001
    Buf[pos++] = fgetc (bits);
    info3 = FindStartCode(&Buf[pos-4], 3);
    if(info3 != 1)
      info2 = FindStartCode(&Buf[pos-3], 2);
    StartCodeFound = (info2 == 1 || info3 == 1);
  }

  //Count the trailing_zero_8bits
  //计算 trailing_zero_8bits,如果start_code为0x000001,trailing_zero_8bits 肯定不存在
  if(info3==1)	//if the detected start code is 00 00 01, trailing_zero_8bits is sure not to be present
  {
    while(Buf[pos-5-TrailingZero8Bits]==0)
      TrailingZero8Bits++;
  }
  // Here, we have found another start code (and read length of startcode bytes more than we should
  // have.  Hence, go back in the file
  rewind = 0;
  if(info3 == 1)
    rewind = -4;
  else if (info2 == 1)
    rewind = -3;
  else
    printf(" Panic: Error in next start code search \n");

  if (0 != fseek (bits, rewind, SEEK_CUR))
  {
    snprintf (errortext, ET_SIZE, "GetAnnexbNALU: Cannot fseek %d in the bit stream file", rewind);
    free(Buf);
    error(errortext, 600);
  }

  // Here the leading zeros(if any), Start code, the complete NALU, trailing zeros(if any)
  // and the next start code is in the Buf.
  // The size of Buf is pos, pos+rewind are the number of bytes excluding the next
  // start code, and (pos+rewind)-startcodeprefix_len-LeadingZero8BitsCount-TrailingZero8Bits
  // is the size of the NALU.

  nalu->len = (pos+rewind)-nalu->startcodeprefix_len-LeadingZero8BitsCount-TrailingZero8Bits;
  memcpy (nalu->buf, &Buf[LeadingZero8BitsCount+nalu->startcodeprefix_len], nalu->len);
  nalu->forbidden_bit = (nalu->buf[0]>>7) & 1;
  nalu->nal_reference_idc = (nalu->buf[0]>>5) & 3;
  nalu->nal_unit_type = (nalu->buf[0]) & 0x1f;


//printf ("GetAnnexbNALU, regular case: pos %d nalu->len %d, nalu->reference_idc %d, nal_unit_type %d \n", pos, nalu->len, nalu->nal_reference_idc, nalu->nal_unit_type);
#if TRACE
  fprintf (p_trace, "\n\nAnnex B NALU w/ %s startcode, len %d, forbidden_bit %d, nal_reference_idc %d, nal_unit_type %d\n\n",
    nalu->startcodeprefix_len == 4?"long":"short", nalu->len, nalu->forbidden_bit, nalu->nal_reference_idc, nalu->nal_unit_type);
  fflush (p_trace);
#endif
  
  free(Buf);
 
  return (pos+rewind);
}
{% endcodeblock %}

找`start_code`的定义如下,该函数的参数`zeros_in_startcode`可能为 3 或 4,寻找`0x000001`或`0x00000001`。  

{% codeblock lang:c FindStartCode %}
/*!
 ************************************************************************
 * \brief
 *    returns if new start code is found at byte aligned position buf.
 *    new-startcode is of form N 0x00 bytes, followed by a 0x01 byte.
 *
 *  \return
 *     1 if start-code is found or                      \n
 *     0, indicating that there is no start code
 *
 *  \param Buf
 *     pointer to byte-stream
 *  \param zeros_in_startcode
 *     indicates number of 0x00 bytes in start-code.
 ************************************************************************
 */
static int FindStartCode (unsigned char *Buf, int zeros_in_startcode)
{
  int info;
  int i;

  info = 1;
  for (i = 0; i < zeros_in_startcode; i++)
    if(Buf[i] != 0)
      info = 0;

  if(Buf[i] != 1)
    info = 0;
  return info;
}
{% endcodeblock %}

## X264 中 Bitstream 的源码分析

`X264`中关于`AnnexB`部分的描述主要是在`common/bitstream.c`中的`void x264_bitstream_init(int cpu, x264_bitstream_function_t *pf)`完成。
其中的`x264_bitstream_function_t`结构体定义如下：  

{% codeblock lang:c x264_bitstream_function_t %}
typedef struct
{
    uint8_t *(*nal_escape) ( uint8_t *dst, uint8_t *src, uint8_t *end );
    void (*cabac_block_residual_internal)( dctcoef *l, int b_interlaced,
                                           intptr_t ctx_block_cat, x264_cabac_t *cb );
    void (*cabac_block_residual_rd_internal)( dctcoef *l, int b_interlaced,
                                              intptr_t ctx_block_cat, x264_cabac_t *cb );
    void (*cabac_block_residual_8x8_rd_internal)( dctcoef *l, int b_interlaced,
                                                  intptr_t ctx_block_cat, x264_cabac_t *cb );
} x264_bitstream_function_t;
{% endcodeblock %}

其中`x264_bitstream_init`的定义如下：  

{% codeblock lang:c X264_bitstream_init %}
void X264_bitstream_init(int cpu, x264_bitstream_function_t *pf)
{
    memset(pf, 0, sizeof(*pf));
    pf->nal_escape = x264_nal_escape_c;
    pf->cabac_block_residual_internal = x264_cabac_block_residual_internal_sse2;
    pf->cabac_block_residual_rd_internal = x264_cabac_block_residual_rd_internal_sse2;
    pf->cabac_block_residual_8x8_rd_internal = x264_cabac_block_residual_8x8_rd_internal_sse2;
}
{% endcodeblock %}

其中的`x264_nal_escape_c`定义如下：  

{% codeblock lang:c x264_nal_escape_c %}
static uint8_t *x264_nal_escape_c( uint8_t *dst, uint8_t *src, uint8_t *end )
{
    if( src < end ) *dst++ = *src++;
    if( src < end ) *dst++ = *src++;
    while( src < end )
    {
        if( src[0] <= 0x03 && !dst[-2] && !dst[-1] )
            *dst++ = 0x03;
        *dst++ = *src++;
    }
    return dst;
}
{% endcodeblock %}

最后，给出 X264 中关于每个 NALU 的编码的实现：  

{% codeblock lang:c x264_nal_encode %}
/****************************************************************************
 * x264_nal_encode:
 ****************************************************************************/
void x264_nal_encode( x264_t *h, uint8_t *dst, x264_nal_t *nal )
{
    uint8_t *src = nal->p_payload;
    uint8_t *end = nal->p_payload + nal->i_payload;
    uint8_t *orig_dst = dst;

    if( h->param.b_annexb )
    {
        if( nal->b_long_startcode )
            *dst++ = 0x00;
        *dst++ = 0x00;
        *dst++ = 0x00;
        *dst++ = 0x01;
    }
    else /* save room for size later */
        dst += 4;

    /* nal header */
    *dst++ = ( 0x00 << 7 ) | ( nal->i_ref_idc << 5 ) | nal->i_type;

    dst = h->bsf.nal_escape( dst, src, end );
    int size = (dst - orig_dst) - 4;

    /* Write the size header for mp4/etc */
    if( !h->param.b_annexb )
    {
        /* Size doesn't include the size of the header we're writing now. */
        orig_dst[0] = size>>24;
        orig_dst[1] = size>>16;
        orig_dst[2] = size>> 8;
        orig_dst[3] = size>> 0;
    }

    nal->i_payload = size+4;
    nal->p_payload = orig_dst;
    x264_emms();
}
{% endcodeblock %}

