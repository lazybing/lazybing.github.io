---
layout: post
title: "AVFormatContext 结构体解析"
date: 2016-06-30 07:42:13 -0700
comments: true
categories: FFMPEG源码分析
---
AVFormatContext 是包含码流参数比较多的结构体，它是 FFmpege 解封装(flv、mp4、rmvb、avi)功能的结构体。一般使用 avformat_alloc_context() 来创建该结构体。
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
