/*
 * hdmi_rx.h
 *
 * Created: 2/17/2019 5:19:32 PM
 *  Author: Steven
 */ 
#ifndef __HDMI_RX_H
#define __HDMI_RX_H

#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #

extern const uint16_t hdmi_rx_address;
extern const uint16_t hdmi_rx_cp_address;
extern const uint16_t hdmi_rx_hdmi_address;
extern const uint16_t hdmi_rx_repeater_address;
extern const uint16_t hdmi_rx_edid_address;
extern const uint16_t hdmi_rx_infoframe_address;
extern const uint16_t hdmi_rx_cec_address;
extern const uint16_t hdmi_rx_dpll_address;

void hdmi_rx_force_freerun();
void hdmi_rx_autofreerun();
void hdmi_rx_set_freerun_to_720p60();
void hdmi_rx_set_freerun_to_1080p60();

void configure_hdmi_rx(void);


#endif