---
layout: post
title: "AVFormatContext 结构体解析"
date: 2016-06-30 07:42:13 -0700
comments: true
categories: FFMPEG源码分析
---
AVFormatContext 是包含码流参数比较多的结构体，
它是 FFmpeg 解封装(flv、mp4、rmvb、avi)功能的结构体。
一般使用`avformat_alloc_context()`来创建该结构体,使用`avformat_free_context`释放该结构体。
<!--more-->

{% codeblock lang:c %}
typedef struct AVFormatContext {
	const AVClass *av_class; 
	struct AVInputFormat *iformat;
	struct AVOutputFormat *oformat;
	void *priv_data;
	AVIOContext *pb;
	int ctx_flags;
	unsigned int nb_streams;
	AVStream **streams;
	char filename[1024];
	int64_t start_time;
	int64_t duration;
	int bit_rate;
    unsigned int packet_size;
    int max_delay;
    int flags;
    const uint8_t *key;
    int keylen;

    unsigned int nb_programs;
    AVProgram **programs;

    enum AVCodecID video_codec_id;
    enum AVCodecID audio_codec_id;
    enum AVCodecID subtitle_codec_id;

    unsigned int max_index_size;
    unsigned int max_picture_buffer;
    unsigned int nb_chapters;
    AVChapter **chapters;
    AVDictionary *metadata;
    int64_t start_time_realtime;
    int fps_probe_size;
    int error_recognition;
    AVIOInterruptCB interrupt_callback;
    int64_t max_interleave_delta;
    int strict_std_compliance;
    int event_flags;
    int max_ts_probe;
    int avoid_negative_ts;
    int ts_id;
    int audio_preload;
    int max_chunk_duration;
    int max_chunk_size;
    int use_wallclock_as_timestamps;
    int avio_flags;
    enum AVDurationEstimationMethod duration_estimation_method;
    int64_t skip_initial_bytes;
    unsigned int correct_ts_overflow;
    int seek2any;
    int probe_score;
    int format_probesize;
    char *codec_whitelist;
    char *format_whitelist;
    AVFormatInternal *internal;
    int io_repositioned;
    AVCodec *video_codec;
    AVCodec *audio_codec;
    AVCodec *subtitle_codec;
    AVCodec *data_codec;
    int metadata_header_padding;
    void *opaque;
    av_format_control_message control_message_cb;
    int64_t output_ts_offset;
    uint8_t *dump_separator;
    enum AVCodecID data_codec_id;
    int (*open_cb)(struct AVFormatContext *s, AVIOContext **p, const char *url, int flags, const AVIOInterruptCB *int_cb, AVDictionary **options);	
}
{% endcodeblock lang:c %}

* struct AVInputFormat *iformat; 输入数据的封装格式，由`avformat_open_input`设置，仅仅在`Demuxing`使用。  
* struct AVOutputFormat *oformat; 输出数据的封装格式，必须由使用者在`avformat_write_header`前设置，由`Muxing`使用。  
* priv_data，在`muxing`中，由`avformat_write_header`设置；在`demuxing`中，由`avformat_open_input`设置。
* AVIOContext *pb;输入数据的缓存。如果`iformat/oformat.flags`设置为`AVFMT_NOFILE`的话，该字段不需要设置。对于`Demuxing`
,需要在`avformat_open_input`前设置，或由`avformat_open_input`设置；对于`Muxing`,在`avformat_write_header`前设置。  
* ctx_flags,码流的信息，表明码流属性的的信号。由`libavformat`设置，例如`AVFMTCTX_NOHEADER`。  
* nb_streams 指`AVFormatContext.streams`的数量，必须由`avformat_new_stream`设置，不能由其他代码改动。  
* AVStream **streams;文件中所有码流的列表，新的码流创建使用`avformat_new_stream`函数。`Demuxing`中，码流由`avformat_open_input`创建。
如果`AVFMTCTX_NOHEADER`被设置，新的码流可以出现在`av_read_frame`中。`Muxing`中，码流在`avformat_write_header`之前由用户创建。它的释放是由`avformat_free_context`完成的。  
* filename,输入或输出的文件名，`Demuxing`中由`avformat_open_input`设置，`Muxing`中在使用`avformat_write_header`前由调用者设置。  
* int64_t duration;码流的时长。  
* bit_rate,比特率。  
* enum AVCodecID video_codec_id;  
* AVDictionary *metadata; 元数据，适用于整个文件。  





