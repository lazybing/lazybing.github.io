---
layout: post
title: "AVStream 结构体解析"
date: 2016-07-03 04:31:41 -0700
comments: true
categories: FFMPEG源码分析
---
AVStream是存储每一个视频/音频流信息的结构体。
<!--more-->

{% codeblock lang:c %}
typedef struct AVStream{

    int index;    	/* stream index in AVFormatContext */
    int id;			/*  Format-specific stream ID */
    AVCodecContext *codec;
    void *priv_data;
    AVRational time_base;
    int64_t start_time;
    int64_t duration;

    int64_t nb_frames;                 ///< number of frames in this stream if known or 0

    int disposition; /**< AV_DISPOSITION_* bit field */

    enum AVDiscard discard; ///< Selects which packets can be discarded at will and do not need to be demuxed.
    AVRational sample_aspect_ratio;

    AVDictionary *metadata;
    AVRational avg_frame_rate;

    AVPacket attached_pic;
    AVPacketSideData *side_data;
    int            nb_side_data;
    int event_flags;
    int pts_wrap_bits; /**< number of bits in pts (used for wrapping control) */
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

}
{% endcodeblock %}
