---
layout: post
title: "AVFrame 结构体解析"
date: 2016-06-28 09:10:38 -0700
comments: true
categories: FFMPEG源码分析 
---

`AVFrame` 这个结构体主要描述了解码后的未压缩的视频和音频数据。
<!--more-->
---
`AVFrame`必须使用`av_frame_alloc()`函数来分配，注意该函数只能分配`AVFrame`，对于分配出的内存需要靠其他方法来管理。`AVFrame`必须由`av_frame_free()`函数释放。`AVFrame`只需分配一次，即可多次重复使用来存储不停的数据data——一个`AVFrame`可以可以存储解码出的多张 frame。

{% codeblock lang:c AVFrame%}

typedef struct AVFrame{

#define AV_NUM_DATA_POINTERS 8
	uint8_t *data[AV_NUM_DATA_POINTERS];
	int linesize[AV_NUM_DATA_POINTERS];
	uint8_t **extended_data;
	int width, height;
	int nb_samples; /* number of audio samples(per channel) described by this frame */
	int format;
	int key_frame; /* 1->keyframe, 0->not*/
	enum AVPictureType pict_type;
	AVRational sample_aspect_ratio;
	int64_t pts;
	int64_t pkt_pts;
	int64_t pkt_dts;
	int coded_picture_number;
	int display_picture_number;
	int quality;
	void *opaque; /* for some private data of the user */
	uint64_t error[AV_NUM_DATA_POINTERS];
	int repeat_pict;
	int interlaced_frame;
	int top_field_first;	/* If the content is interlaced, is top field displayed first */
	int palette_has_changed;
    int64_t reordered_opaque;
    int sample_rate;    /*Sample rate of the audio data*/
    uint64_t channel_layout; /*channel layout of the audio data*/
    AVBufferRef *buf[AV_NUM_DATA_POINTERS];
    AVBufferRef **extended_buf;
    int nb_exteneded_buf;
    AVFrameSideData **side_data;
    int nb_side_data;
#define AV_FRAME_FLAG_CORRUPT   (1<<0)
    int flags;
    enum AVColorRange color_range;
    enum AVColorPrimaries color_primaries;
    enum AVColorTransferCharacteristic color_trc;
    enum AVColorSpace colorspace;
    enum AVChromaLocation chroma_location;

    int64_t best_effort_timestamp;
    int64_t pkt_pos;
    int64_t pkt_duration;
    AVDictionary *metadata;
    int decode _error_flags;
#define FF_DECODE_ERROR_INVALID_BITSTREAM   1
#define FF_DECODE_ERROR_MISSING_REFERENCE   2
    int channels;
    int pkt_size;
    AVBufferRef *qp_table_buf;
}

{% endcodeblock %}

视频帧的宽高  
```
int width, height;
```

由该帧描述的音频样本的数目  
```
int nb_samples;
```

帧格式，-1 表示未设置的帧格式或者未知的帧格式，  
对于视频帧，该值为`enum AVPixelFormat`, 例如`AV_PIX_FMT_YUV420P`  
对于音频帧，该值为`enum AVSampleFormat`, 例如`AV_SAMPLE_FMT_S16`  
```
int format;
```

关键帧：1 表示关键帧，0 表示非关键帧  
```
int key_frame;
```

帧图片类型，例如I/P/B  
```
enum AVPictureType pict_type;
```

帧的长宽比，0/1为未知/不确定
```
/**
 * rational number numerator/denominator
 */
typedef struct AVRational{
    int num; ///< numerator
    int den; ///< denominator
} AVRational;

AVRational sample_aspect_ratio;
```

显示时间戳（决定何时显示）
```
/**
 * Presentation timestamp in time_base units (time when frame should be shown to user).
 */
int64_t pts;
```

解码时间戳 (决定何时解码)  
```
/* PTS copied from the AVPacket that was decoded to produce this frame */
int64_t pkt_pts;
```

解码序列和显示序列（Display Order / Decoded Order）  
```
int coded_picture_number; /* picture number in bitstream order */
int display_picture_number; /* picture number in display order */
```

品质(介于 1(最好) 和 FF_LAMBDA_MAX(坏) 之间 )  
```
int quality;
```


