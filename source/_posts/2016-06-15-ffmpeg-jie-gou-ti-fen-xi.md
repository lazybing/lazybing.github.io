---
layout: post
title: "FFmpeg 常用结构体解析"
date: 2016-06-15 17:56:18 -0700
comments: true
categories: FFMPEG源码分析
---

* list element with functor item
{:toc}

[FFMpeg](https://ffmpeg.org/) 作为音视频领域的开源工具，它几乎可以实现所有针对音视频的处理。本文详细记录使用 FFMpeg 开发过程中，经常使用到的结构体的含义以及使用场景。
<!--more-->

首先，我们从 FFMpeg 主要完成的功能视频编解码开始，编解码的大致流程可以使用如下图表示：

{% img /images/ffmpeg_struct/ffmpeg_transcode.png %}

##AVPacket结构体解析

从上面的图中可以看出，解复用器 Demuxer 输出的 packets data 作为解码器 Decoder 的输入；同时也是编码器 Encoder 的输出，复用器 Muxer 的输入。

FFMpeg 中使用 AVpacket 结构定义图中描述的 packet。该结构保存了压缩数据，它由 demuxers 输出，之后作为 decoders 的输入；或作为 encoders 的输出，之后作为 muxers 的输入。

对于视频数据，它只包含一帧压缩数据；对于音频数据，它可能包含多帧压缩数据。

{% codeblock lang:c AVPacket %}
typedef struct AVPacket{
	AVBufferRef *buf;
	int64_t      pts;
	int64_t      dts;
	uint8_t    *data;
	int         size;
	int stream_index;
	int        flags;
	AVPacketSideData *side_data;
	int side_data_elems;
	int   duration;
	int64_t pos;
	int64_t convergence_duration;
}
{% endcodeblock %}

* pts：显示时间戳，它的单位是 AVStream->time_base；如果在文件中没有保存这个值，它被设置为 AV_NOPTS_VALUE。由于图像显示不可能早于图像解压，因此 PTS 必须比 DTS（解码时间戳）大或者相等。某些文件格式中可能会使用 PTS/DTS 表示其他含义，此时时间戳必须转为真正的时间戳才能保存到 AVPacket 结构中。
* dts：解码时间戳，它的单位是 AVStream->time_base，表示压缩视频解码的时间，如果文件中没有保存该值，它被设置为 AV_NOPTS_VALUE。
* data：指向真正的压缩编码的数据。
* size：表示该 AVPacket 结构中 data 字段所指向的压缩数据的大小。
* stream_index：标识该 AVPacket 结构所属的视频流或音频流。
* duration:该 AVPacket 包以 AVStream->time_base 为单位，所持续的时间，0 表示未知，或者为显示时间戳的差值(next_pts - this pts)。
* pos：表示该 AVPacket 数据在媒体中的位置，即字节偏移量。

由上面的图可以看出，该结构主要用于解码器(Decoder)或编码器(Encoder),一般使用方法代码示例如下：

{% codeblock lang:c %}
AVPacket avpkt;
av_init_packet(&avpkt);
avpkt.size = ...
avpkt.data = ...
{% endcodeblock %}

##AVFrame结构体解析

上面已经分析了压缩域的表示结构体 AVPacket 结构，与之相对于的，FFMpeg 为之提供的表示像素域的结构体为 AVFrame 结构。从上面的图中也可以看出，Frame 主要作为解码器的输出、编码器的输入。AVFrame 结构主要用来描述未压缩的视频或音频数据，比如视频的 YUV 数据、RGB 数据，音频的 PCM 数据等。

AVFrame 结构体必须使用`av_frame_alloc()`分配，注意该函数只是分配了 AVFrame 结构本身，它的 data 区域要用其他方式管理；该结构体的释放要用`av_frame_free()`。

AVFrame 结构体通常只需分配一次，之后即可通过保存不同的数据来重复多次使用，比如一个 AVFrame 结构可以保存从解码器中解码出的多帧数据。此时，就可以使用`av_frame_unref()`释放任何由 Frame 保存的参考帧并还原回最原始的状态。

{% codeblock lang:c AVFrame %}

typedef struct AVFrame{
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

    int channels;
    int pkt_size;
    AVBufferRef *qp_table_buf;
}
{% endcodeblock %}

* data：指向图片或信道的指针，与初始化时分配的大小可能不同，一些解码器取数据范围超出(0,0)-(width, height),具体请查看`avcodec_align_dimensions2()`方法。一些过滤器或扫描器读数据时可能会超过 16 字节，所以当它们使用时，必须额外分配 16 字节。对于 packed 格式的数据(例如 RGB24)，会存放到 data[0] 里面；对于 planar 格式的数据(例如 YUV420P)，则会分开 data[0]/data[1]/data[2]（YUV420P 中 data[0] 存放 Y，data[1] 存放 U，data[2] 存放 V）。
* linesize：对于视频数据，表示每个图像行的字节大小；对于音频数据，表示每个 Plane 的字节大小，只有linesize[0]可以设置，对于plane 音频，每个信道 channel 必须是相同的。对于视频的 linesize 应为 CPU 的对准要求的倍数，一般为 32。注意 linesize 可大于可用的数据的尺寸，有可能存在由于性能原因额外填充。
* width/height:视频的宽高
* format：帧格式,-1表示未设置的帧格式。对于视频帧，该值为 enum 类型的 AVPixelFormat，例如 AV_PIX_FMT_YUV420P；对于音频帧，该值为 enum 型的 AVSampleFormat，例如 AV_SAMPLE_FMT_S16。
* key_frame:关键帧，1 表示关键帧，0 表示非关键帧。
* pict_type：帧图片类型，例如 I/P/B。
* sample_aspect_ration：帧像素的宽高比，使用 AVRational 表示。
* pts：显示时间戳，单位为 time_base。
* pkt_pts：该 PTS 是从 AVPacket 结构中拷贝过来的；与之对应的是pkt_dts。
* coded_picture_number/display_picture_number：解码序列号和显示序列号（Display Order/Decoded Order）。
* interlaced_frame:表示该帧为 interlace 码流或者为 progressive 码流。
* top_field_first:对于 interlace 码流，表示该它是 top first or bottom first。

##AVCodec结构体解析
上面分析了像素域的表示结构体 AVFrame 和 压缩域的表示结构体 AVPacket，两者之间的转换是通过编解码器来完成的，FFMpeg 中使用 AVCodec 结构体表示编解码。本小节就来看一下 AVCodec 结构体。

{% codeblock lang:c AVCodec %}
typedef struct AVCodec{
	const char *name;
    const char *long_name;
    enum AVMediaType type;
    enum AVCodecID id;
    int capabilities;
    const AVRational *supported_framerates; ///< array of supported framerates, or NULL if any, array is terminated by {0,0}
    const enum AVPixelFormat *pix_fmts;     ///< array of supported pixel formats, or NULL if unknown, array is terminated by -1
    const int *supported_samplerates;       ///< array of supported audio samplerates, or NULL if unknown, array is terminated by 0
    const enum AVSampleFormat *sample_fmts; ///< array of supported sample formats, or NULL if unknown, array is terminated by -1
    const uint64_t *channel_layouts;         ///< array of support channel layouts, or NULL if unknown. array is terminated by 0
    uint8_t max_lowres;                     ///< maximum value for lowres supported by the decoder, no direct access, use av_codec_get_max_lowres()
    const AVClass *priv_class;              ///< AVClass for the private context
    const AVProfile *profiles;              ///< array of recognized profiles, or NULL if unknown, array is terminated by {FF_PROFILE_UNKNOWN}
    int priv_data_size;
    struct AVCodec *next;
    int (*init_thread_copy)(AVCodecContext *);
    int (*update_thread_context)(AVCodecContext *dst, const AVCodecContext *src);
    const AVCodecDefault *defaults;
    void (*init_static_data)(struct AVCodec *codec);

    int (*init)(AVCodecContext *);
    int (*encode_sub)(AVCodecContext *, uint8_t *buf, int buf_size,
    int (*encode2)(AVCodecContext *avctx, AVPacket *avpkt, const AVFrame *frame,
                   int *got_packet_ptr);
    int (*decode)(AVCodecContext *, void *outdata, int *outdata_size, AVPacket *avpkt);
    int (*close)(AVCodecContext *);
    void (*flush)(AVCodecContext *);
    int caps_internal;
}
{% endcodeblock %}

* name:具体的 CODEC 的名称的简短描述，比如"HEVC"/"H264"等。
* long_name: CODEC 名称的详细描述，比如"HEVC (High Efficiency Video Coding)"。
* type:媒体类型的字段，它是 enum 型的，表示视频、音频、字幕等，比如AVMEDIA_TYPE_VIDEO、AVMEIDA_TYPE_AUDIO。
* id：唯一标识的 CODEC 类型，比如 AV_CODEC_ID_HEVC。
* supported_framerates:支持的视频帧率的数组，以{0，0}作为结束。
* pix_fmts:编解码器支持的图像格式的数组，以 -1 作为结束。
* profiles:编解码器支持的 Profile，以 HEVC 为例，包含"Main""Main10""Main Still Picture"。

每一个编解码器对应一个 AVCodec 结构体，对应一种编解码方式，比如 HEVC、AVC、MPEG2、MPEG4、VP6、VP8、VP9等。以 HEVC 为例，FFMpeg中关于 AVCodec 的定义如下：

{% codeblock lang:c ff_hevc_decoder %}
AVCodec ff_hevc_decoder = {
    .name                  = "hevc",
    .long_name             = NULL_IF_CONFIG_SMALL("HEVC (High Efficiency Video Coding)"),
    .type                  = AVMEDIA_TYPE_VIDEO,
    .id                    = AV_CODEC_ID_HEVC,
    .priv_data_size        = sizeof(HEVCContext),
    .priv_class            = &hevc_decoder_class,
    .init                  = hevc_decode_init,
    .close                 = hevc_decode_free,
    .decode                = hevc_decode_frame,
    .flush                 = hevc_decode_flush,
    .update_thread_context = hevc_update_thread_context,
    .init_thread_copy      = hevc_init_thread_copy,
    .capabilities          = AV_CODEC_CAP_DR1 | AV_CODEC_CAP_DELAY |
                             AV_CODEC_CAP_SLICE_THREADS | AV_CODEC_CAP_FRAME_THREADS,
    .profiles              = NULL_IF_CONFIG_SMALL(profiles),
};
{% endcodeblock %}

各种不同的编解码器，FFMpeg 使用注册函数`avcodec_register_all()`来完成。

关于 AVCodec 的通常使用方法：首先，根据特定的 ID 找到特定的编解码器；其次，根据特定的编解码器分配出特定的描述编解码上下文的 AVCodecContext 结构体；之后，打开编解码器；最后，调用编解码器进行编解码。示例代码如下：

{% codeblock lang:c %}
AVCodec *codec = NULL;
AVCodecContext *ctx = NULL;

codec = avcodec_find_decoder(origin_ctx->codec_id);
ctx = avcodec_alloc_context3(codec);
avcodec_open2(ctx, codec, NULL);
...
{% endcodeblock %}

##AVCodecContext结构体解析

AVCodecContext 可能是最复杂的结构体了。因为结构体内的变量非常多，不可能一一分析，而且有的变量是编码时候用到、有的是解码时候用到，此处只对几个常用的变量做简要的记录。


{% codeblock lang:c %}
typedef struct AVCodecContext{
	const AVClass *av_class;
	int log_level_offset;
	enum AVMediaType codec_type;
	const struct AVCodec *codec;
	enum AVCodecID     codec_id;
	unsigned int codec_tag;
	void *priv_data;
	struct AVCodecInternal *internal;
	void *opaque;
	int bit_rate;
	int bit_rate_tolerance;
	int global_quality;
	int compression_level;
	int flags;
	int flags2;
	uint8_t *extradata;
	int extradata_size;
	AVRational time_base;
	int ticks_per_frame;
	int delay;
	int width, height;
	int coded_width, coded_height;
	int gop_size;
	enum AVPixelFormat pix_fmt;
	void (*draw_horiz_band)(struct AVCodecContext *s,
                            const AVFrame *src, int offset[AV_NUM_DATA_POINTERS],
                            int y, int type, int height);
	enum AVPixelFormat (*get_format)(struct AVCodecContext *s, const enum AVPixelFormat * fmt);
	int max_b_frames;
	float b_quant_factor;
	int b_frame_strategy;
	float b_quant_offset;
	int has_b_frames;
	int mpeg_quant; 		/*decoding: unused*/
	float i_quant_factor; 	/*decoding: unused*/
	float i_quant_offset; 	/*decoding: unused*/
	float lumi_masking;		/*decoding: unused*/
	float temporal_cplx_masking; /*decoding: unused*/
	float spatial_cplx_masking;  /*decoding: unused*/
	float p_masking;		/*decoding: unused*/
	float dark_masking;		/*decoding: unused*/
	int slice_count;
	int prediction_method;	/*decoding: unused*/
	int *slice_offset;
	AVRational sample_aspect_ratio;
	int me_cmp;				/*decoding: unused*/
	int me_sub_cmp;			/*decoding: unused*/
	int mb_cmp;				/*decoding: unused*/
    ...
}AVCodecContext;

{% endcodeblock %}

* AVMediaType codec_type:编解码器的类型，如音频、视频、字幕。
* AVCdec *codec:采用的解码器 AVCodec。
* bit_rate: 平均比特率。
* int width, height: 视频的宽高。
* int refs: 运动估计参考帧的个数。
* int sample_rate: 采样率。
* int channels: 声道数。

AVCodecContext 使用 avcodec_alloc_context3 分配，该函数除了分配 AVCodecContext 外，还会初始化默认的字段。分配的内存必须通过 avcodec_free_context 释放。

上面提到的几个结构体 AVCodec/AVCodecContext，联合使用，通常是如下形式：

{% codeblock lang:c %}
avcodec_register_all();
...
codec = avcodec_find_decoder(AV_CODEC_ID_H264);
if(!codec)
    exit(1);

context = avcodec_alloc_context3(codec);

if(avcodec_open2(context, codec, opts) < 0)
    exit(1);

{% endcodeblock %}

##AVStream结构体解析

AVStream用于存储一个视频流、音频流的结构体。

{% codeblock lang:c AVStream %}
typedef struct AVStream{
	int index;	//stream index in AVFormatContext
	int id;
	AVCodecContext *codec;
	void *priv_data;
	AVRational time_base;
	int64_t start_time;
	int64_t duration;
	int64_t nb_frames;
	int disposition;
	enum AVDiscard discard;
	AVRational sample_aspect_ratio;
	AVDictionary *metadata;
	AVRational avg_frame_rate;
	AVPacket attached_pic;
	AVPacketSideData *side_data;
	int            nb_side_data;
	int event_flags;
	int pts_wrap_bits;
    int64_t first_dts;
    int64_t cur_dts;
    int64_t last_IP_pts;
    int last_IP_duration;
	int probe_packets;
	int codec_info_nb_frames;

    /* av_read_frame() support */
    enum AVStreamParseType need_parsing;
    struct AVCodecParserContext *parser;
    struct AVPacketList *last_in_packet_buffer;
    AVProbeData probe_data;
	#define MAX_REORDER_DELAY 16
    int64_t pts_buffer[MAX_REORDER_DELAY+1];

    AVIndexEntry *index_entries; /**< Only used if the format does not
                                    support seeking natively. */
    int nb_index_entries;
    unsigned int index_entries_allocated_size;
    AVRational r_frame_rate;
    int stream_identifier;

    int64_t interleaver_chunk_size;
    int64_t interleaver_chunk_duration;
    int request_probe;
    int skip_to_keyframe;
    int skip_samples;
    int64_t start_skip_samples;
    int64_t first_discard_sample;
    int64_t last_discard_sample;
    int nb_decoded_frames;
    int64_t mux_ts_offset;
    int64_t pts_wrap_reference;
    int pts_wrap_behavior;
    int update_initial_durations_done;
    int64_t pts_reorder_error[MAX_REORDER_DELAY+1];
    uint8_t pts_reorder_error_count[MAX_REORDER_DELAY+1];
    int64_t last_dts_for_order_check;
    uint8_t dts_ordered;
    uint8_t dts_misordered;
    int inject_global_side_data;
    char *recommended_encoder_configuration;
    AVRational display_aspect_ratio;

    struct FFFrac *priv_pts;
}AVStream;
{% endcodeblock %}

* index:标识该视频流、音频流，是 AVFormatContext 中的流索引。
* AVCodecContext *codec:指向该视频、音频流的内容。
* AVRational time_base:通过该值可以把 PTS/DTS 转化为真正的时间。
* int64_t duration:该视频、音频流长度。
* AVDictionary *metadata: 元数据信息。
* AVRational avg_frame_rate: 帧率。

## AVFormatContext 结构体解析

AVFormatContext 是包含码流参数比较多的结构体，
它是 FFmpeg 解封装(flv、mp4、rmvb、avi)功能的结构体。
一般使用 avformat_alloc_context() 来创建该结构体,使用 avformat_free_context 释放该结构体。

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


##参考文章：  
1.[FFMPEG结构体分析：AVFrame](http://blog.csdn.net/leixiaohua1020/article/details/14214577)  
2.[FFMPEG结构体分析：AVFrame](http://www.jianshu.com/p/18fa498eb19e)  
3.[ FFMPeg代码分析：AVFrame结构体及其相关的函数](http://blog.csdn.net/shaqoneal/article/details/16959671)  
