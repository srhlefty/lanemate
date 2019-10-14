#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #
#include <string.h>
#include "utils.h"
#include "i2c.h"
#include "uart.h"
#include "hdmi_rx.h"

void onVSYNC(void);

void config_interrupts(void);
void config_interrupts(void)
{
    struct extint_chan_conf eic_settings;
    extint_chan_get_config_defaults(&eic_settings);
	// VSYNC is connected to PA25, which can be configured to EXTINT[5]
    eic_settings.gpio_pin           = PIN_PA25A_EIC_EXTINT5;
    eic_settings.gpio_pin_mux       = MUX_PA25A_EIC_EXTINT5;
    eic_settings.gpio_pin_pull      = EXTINT_PULL_NONE;
    eic_settings.detection_criteria = EXTINT_DETECT_FALLING;
	// 5 because we're on EXTINT[5]
    extint_chan_set_config(5, &eic_settings);

    extint_register_callback(onVSYNC, 5, EXTINT_CALLBACK_TYPE_DETECT);
    extint_chan_enable_callback(5, EXTINT_CALLBACK_TYPE_DETECT);

	system_interrupt_enable_global();
}


const uint16_t hdmi_tx_address = 0x72 >> 1;
const uint16_t sd_rx_address = 0x40 >> 1;
const uint16_t lanemate_address = 0b0101100;

// Per wikipedia (Serial Presence Detect), the SA0-2 lines on a ddr stick
// set the I2C address to be in the range 0x50 to 0x57. The current board
// configuration ties those lines low, resulting in the address 0x50.
const uint16_t ddr_address = 0x50;

typedef struct regdata_
{
	uint8_t reg;
	uint8_t val_hd;
	uint8_t val_sd;
}regdata;

const uint8_t tx_table_size = 40;
const regdata tx_data[40] = {
	// Reg		HDMI		SD			Default?	Description
	{	0x41	,	0x50	,	0x50	},	//	custom	Power down
	{	0x41	,	0x10	,	0x10	},	//	custom	Power up
//	{	0x01	,	0x00	,	0x00	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
//	{	0x02	,	0x00	,	0x00	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
//	{	0x03	,	0x00	,	0x00	},	//	default	20 bit N used with CTS to regenerate the audio clock in the receiver.
//	{	0x07	,	0x00	,	0x00	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
//	{	0x08	,	0x00	,	0x00	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
//	{	0x09	,	0x00	,	0x00	},	//	default	Cycle Time Stamp (CTS) Manually Entered This 20 bit value is used in the receiver with the N value to regenerate an audio clock. For remaining bits see 0x08 and 0x09.
//	{	0x0A	,	0x01	,	0x01	},	//	default	CTS select, Audio Select, Audio Mode, MCLK ratio
//	{	0x0B	,	0x0e	,	0x0e	},	//	default	SPDIF enable, Audio clock polarity, MCLK enable, Fixed
//	{	0x0C	,	0xbc	,	0xbc	},	//	default	Audio sampling frequency select, Channel status override, I2S3 enable, I2S2 enable, I2S1 enable, I2S0 enable, I2S format
//	{	0x0D	,	0x18	,	0x18	},	//	default	I2S bit width
//	{	0x0E	,	0x01	,	0x01	},	//	default	Subpacket 0 L source, Subpacket 0 R source
//	{	0x0F	,	0x13	,	0x13	},	//	default	Subpacket 1 L source, Subpacket 1 R source
//	{	0x10	,	0x25	,	0x25	},	//	default	Subpacket 2 L source, Subpacket 2 R source
//	{	0x11	,	0x37	,	0x37	},	//	default	Subpacket 3 L source, Subpacket 3 R source
//	{	0x12	,	0x00	,	0x00	},	//	default	Audio sample word (CS bit 1), Consumer Use (CS bit 0), Copyright Bit (CS bit 2), Additional Audio Info (CS bits 5-3), Audio Clock Accuracy (CS bits 29-28)
//	{	0x13	,	0x00	,	0x00	},	//	default	Category Code (CS bits 15-8)
//	{	0x14	,	0x00	,	0x00	},	//	default	Source Number (CS bits 19-16), Word Length (CS bits 35-32)
	{	0x15	,	0x00	,	0x03	},	//	custom	I2S Sampling Frequency (CS bits 27-24), Input Video Format
	{	0x16	,	0x34	,	0x34	},	//	custom	Output Format, Reserved, Color Depth, Input Style, DDR Input Edge, Output Colorspace for Black Image
	{	0x17	,	0x06	,	0x04	},	//	custom	Fixed, Vsync Polarity, Hsync Polarity, Reserved, Interpolation Style, Aspect Ratio, DE Generator Enable
	{	0x18	,	0x00	,	0xe6	},	//	custom	CSC Enable, CSC Scaling Factor, A1 (CSC)
	{	0x19	,	0x00	,	0x69	},	//	custom	A1 (CSC)
	{	0x1A	,	0x00	,	0x04	},	//	custom	Coefficient Update, A2 (CSC)
	{	0x1B	,	0x00	,	0xac	},	//	custom	A2 (CSC)
	{	0x1C	,	0x00	,	0x00	},	//	custom	A3 (CSC)
	{	0x1D	,	0x00	,	0x00	},	//	custom	A3 (CSC)
	{	0x1E	,	0x00	,	0x1c	},	//	custom	A4 (CSC)
	{	0x1F	,	0x00	,	0x81	},	//	custom	A4 (CSC)
	{	0x20	,	0x00	,	0x1c	},	//	custom	B1 (CSC)
	{	0x21	,	0x00	,	0xbc	},	//	custom	B1 (CSC)
	{	0x22	,	0x00	,	0x04	},	//	custom	B2 (CSC)
	{	0x23	,	0x00	,	0xad	},	//	custom	B2 (CSC)
	{	0x24	,	0x00	,	0x1e	},	//	custom	B3 (CSC)
	{	0x25	,	0x00	,	0x63	},	//	custom	B3 (CSC)
	{	0x26	,	0x00	,	0x02	},	//	custom	B4 (CSC)
	{	0x27	,	0x00	,	0x20	},	//	custom	B4 (CSC)
	{	0x28	,	0x00	,	0x1f	},	//	custom	C1 (CSC)
	{	0x29	,	0x00	,	0xfe	},	//	custom	C1 (CSC)
	{	0x2A	,	0x00	,	0x04	},	//	custom	C2 (CSC)
	{	0x2B	,	0x00	,	0xad	},	//	custom	C2 (CSC)
	{	0x2C	,	0x00	,	0x08	},	//	custom	C3 (CSC)
	{	0x2D	,	0x00	,	0x1a	},	//	custom	C3 (CSC)
	{	0x2E	,	0x00	,	0x1b	},	//	custom	C4 (CSC)
	{	0x2F	,	0x00	,	0xa9	},	//	custom	C4 (CSC)
//	{	0x30	,	0x00	,	0x00	},	//	default	Hsync Placement (Embedded Sync Decoder)
//	{	0x31	,	0x00	,	0x00	},	//	default	Hsync Placement, Hsync Duration
//	{	0x32	,	0x00	,	0x00	},	//	default	Vsync Placement
//	{	0x33	,	0x00	,	0x00	},	//	default	Vsync Placement, Vsync Duration
//	{	0x34	,	0x00	,	0x00	},	//	default	Vsync Duration
//	{	0x35	,	0x00	,	0x00	},	//	default	Hsync Delay
//	{	0x36	,	0x00	,	0x00	},	//	default	Hsync Delay, Vsync Delay
//	{	0x37	,	0x00	,	0x00	},	//	default	Interlace Offset, Active Width
//	{	0x38	,	0x00	,	0x00	},	//	default	Active Width
//	{	0x39	,	0x00	,	0x00	},	//	default	Active Height
//	{	0x3A	,	0x00	,	0x00	},	//	default	Active Height
//	{	0x3B	,	0x80	,	0x80	},	//	default	Reserved, PR Mode, PR PLL Manual, PR Value Manual, Reserved
//	{	0x3C	,	0x00	,	0x00	},	//	default	VIC Manual
//	{	0x40	,	0x00	,	0x00	},	//	default	GC Packet Enable, SPD Packet Enabled, MPEG Packet Enabled, ACP Packet Enable, ISRC Packet Enable, GM Packet Enable, Space Packet 2 Enable, Spare Packet 1 Enable
//	{	0x43	,	0x7e	,	0x7e	},	//	default	EDID Memory I2C Address
//	{	0x44	,	0x79	,	0x79	},	//	default	Reserved, N CTS Packet Enable, Audio Sample Packet Enable, AVI InfoFrame Enable, Audio InfoFrame Enable, Fixed, Packet Read Mode
//	{	0x45	,	0x70	,	0x70	},	//	default	Packet Memory I2C Address
//	{	0x46	,	0x00	,	0x00	},	//	default	Fixed
//	{	0x47	,	0x00	,	0x00	},	//	default	Fixed, PaPb Sync, Audio Sample 3 Valid, Audio Sample 2 Valid, Audio Sample 1 Valid, Audio Sample 0 Valid
//	{	0x48	,	0x00	,	0x00	},	//	default	Reserved, Video Input Bus Reverse, Fixed, Video Input Justification
//	{	0x49	,	0xa8	,	0xa8	},	//	default	Reserved
//	{	0x4A	,	0x80	,	0x80	},	//	default	Auto Checksum Enable, AVI Packet Update, Audio InfoFrame Packet Update, GC Packet Update
//	{	0x4B	,	0x00	,	0x00	},	//	default	Clear AV Mute, Set AV Mute
//	{	0x4C	,	0x00	,	0x00	},	//	default	Fixed
//	{	0x4D	,	0x00	,	0x00	},	//	default	GC Byte 2
//	{	0x4E	,	0x00	,	0x00	},	//	default	GC Byte 3
//	{	0x4F	,	0x00	,	0x00	},	//	default	GC Byte 4
//	{	0x50	,	0x00	,	0x00	},	//	default	GC Byte 5
//	{	0x51	,	0x00	,	0x00	},	//	default	GC Byte 6
//	{	0x52	,	0x02	,	0x02	},	//	default	AVI InfoFrame Version
//	{	0x53	,	0x0d	,	0x0d	},	//	default	AVI InfoFrame Length
//	{	0x54	,	0x00	,	0x00	},	//	default	AVI InfoFrame Checksum
//	{	0x55	,	0x00	,	0x00	},	//	default	AVI Byte 1 bit 7, Y1Y0, Active Format Information Status, Bar Information, Scan Information
//	{	0x56	,	0x00	,	0x00	},	//	default	Colorimetry, Picture Aspect Radio, Active Format Aspect Ratio
//	{	0x57	,	0x00	,	0x00	},	//	default	ITC, EC[2:0], Q[1:0], Non-Uniform Picture Scaling
//	{	0x58	,	0x00	,	0x00	},	//	default	Byte 4 Bit 7 (AVI InfoFrame)
//	{	0x59	,	0x00	,	0x00	},	//	default	Byte 5 bit [7:4] (AVI InfoFrame)
//	{	0x5A	,	0x00	,	0x00	},	//	default	Active Line Start LSB
//	{	0x5B	,	0x00	,	0x00	},	//	default	Active Line Start MSB
//	{	0x5C	,	0x00	,	0x00	},	//	default	Active Line End LSB
//	{	0x5D	,	0x00	,	0x00	},	//	default	Active Line End MSB
//	{	0x5E	,	0x00	,	0x00	},	//	default	Active Pixel Start LSB
//	{	0x5F	,	0x00	,	0x00	},	//	default	Active Pixel Start MSB
//	{	0x60	,	0x00	,	0x00	},	//	default	Active Pixel End LSB
//	{	0x61	,	0x00	,	0x00	},	//	default	Active Pixel End MSB
//	{	0x62	,	0x00	,	0x00	},	//	default	Byte 14 (AVI InfoFrame)
//	{	0x63	,	0x00	,	0x00	},	//	default	Byte 15 (AVI InfoFrame)
//	{	0x64	,	0x00	,	0x00	},	//	default	Byte 16 (AVI InfoFrame)
//	{	0x65	,	0x00	,	0x00	},	//	default	Byte 17 (AVI InfoFrame)
//	{	0x66	,	0x00	,	0x00	},	//	default	Byte 18 (AVI InfoFrame)
//	{	0x67	,	0x00	,	0x00	},	//	default	Byte 19 (AVI InfoFrame)
//	{	0x68	,	0x00	,	0x00	},	//	default	Byte 20 (AVI InfoFrame)
//	{	0x69	,	0x00	,	0x00	},	//	default	Byte 21 (AVI InfoFrame)
//	{	0x6A	,	0x00	,	0x00	},	//	default	Byte 22 (AVI InfoFrame)
//	{	0x6B	,	0x00	,	0x00	},	//	default	Byte 23 (AVI InfoFrame)
//	{	0x6C	,	0x00	,	0x00	},	//	default	Byte 24 (AVI InfoFrame)
//	{	0x6D	,	0x00	,	0x00	},	//	default	Byte 25 (AVI InfoFrame)
//	{	0x6E	,	0x00	,	0x00	},	//	default	Byte 26 (AVI InfoFrame)
//	{	0x6F	,	0x00	,	0x00	},	//	default	Byte 27 (AVI InfoFrame)
//	{	0x70	,	0x01	,	0x01	},	//	default	Audio InfoFrame Version
//	{	0x71	,	0x0a	,	0x0a	},	//	default	Audio InfoFrame Length
//	{	0x72	,	0x00	,	0x00	},	//	default	Audio InfoFrame Checksum
//	{	0x73	,	0x00	,	0x00	},	//	default	Coding Type, Byte 1 bit 3, CC
//	{	0x74	,	0x00	,	0x00	},	//	default	Byte 2 bit [7:5], Sampling Frequency, Sample Size
//	{	0x75	,	0x00	,	0x00	},	//	default	Byte 3
//	{	0x76	,	0x00	,	0x00	},	//	default	Speaker Mapping
//	{	0x77	,	0x00	,	0x00	},	//	default	DM_INH, Level Shift, Byte 5 bit [2], LFEPBL[1:0]
//	{	0x78	,	0x00	,	0x00	},	//	default	Byte 6 (Audio InfoFrame)
//	{	0x79	,	0x00	,	0x00	},	//	default	Byte 7 (Audio InfoFrame)
//	{	0x7A	,	0x00	,	0x00	},	//	default	Byte 8 (Audio InfoFrame)
//	{	0x7B	,	0x00	,	0x00	},	//	default	Byte 9 (Audio InfoFrame)
//	{	0x7C	,	0x00	,	0x00	},	//	default	Byte 10 (Audio InfoFrame)
//	{	0x92	,	0x00	,	0x00	},	//	default	Wake Up Opcode Interrupt 1-8 Enable
//	{	0x93	,	0x00	,	0x00	},	//	default	Wake Up Opcode Interrupt 1-8 detected
//	{	0x94	,	0xc0	,	0xc0	},	//	default	HPD Interrupt Enable, Monitor Sense Interrupt Enable, Vsync Interrupt Enable, Audio FIFO Full Interrupt Enable, Fixed, EDID Ready Interrupt Enable, HDCP Authenticated Interrupt Enable, Fixed
//	{	0x95	,	0x00	,	0x00	},	//	default	DDC Controller Error Interrupt Enable, BKSV Flag Interrupt Enable, CEC Tx Ready Interrupt Enable, CEC Tx Arbitration Lost Interrupt Enable, CEC Tx Retry Timeout Interrupt Enable, CEC Rx Ready 3 Interrupt Enable, CEC Rx Ready 2 Interrupt Enable, CEC Rx Ready 1 Interrupt Enable
//	{	0x96	,	0x00	,	0x00	},	//	default	HPD Interrupt, Monitor Sense Interrupt, Vsync Interrupt, Audio FIFO Full Interrupt, Fixed, EDID Ready Interrupt, HDCP Authenticated, Fixed
//	{	0x97	,	0x00	,	0x00	},	//	default	DDC Controller Error Interrupt, BKSV Flag Interrupt, Tx Ready Interrupt, Tx Arbitration Lost Interrupt, Tx Retry Timeout Interrupt, Rx Ready 3 Interrupt, Rx Ready 2 Interrupt, Rx Ready 1 Interrupt
	{	0x98	,	0x03	,	0x03	},	//	custom	Fixed
//	{	0x99	,	0x02	,	0x02	},	//	default	Fixed
	{	0x9A	,	0xe0	,	0xe0	},	//	custom	Fixed
//	{	0x9B	,	0x18	,	0x18	},	//	default	Fixed
	{	0x9C	,	0x30	,	0x30	},	//	custom	Fixed
	{	0x9D	,	0x61	,	0x61	},	//	custom	Fixed, Input Pixel Clock Divide, Fixed
//	{	0x9F	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xA1	,	0x00	,	0x00	},	//	default	Fixed, Monitor Sense Power Down, Channel 0 PD, Channel 1 PD, Channel 2 PD, Clock Driver PD
	{	0xA2	,	0xa4	,	0xa4	},	//	custom	Fixed
	{	0xA3	,	0xa4	,	0xa4	},	//	custom	Fixed
//	{	0xA4	,	0x08	,	0x08	},	//	default	Fixed
//	{	0xA5	,	0x04	,	0x04	},	//	default	Fixed
//	{	0xA6	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xA7	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xA8	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xA9	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xAA	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xAB	,	0x40	,	0x40	},	//	default	Fixed
	{	0xAF	,	0x04	,	0x04	},	//	custom	HDCP Enable, Fixed, Frame Encryption, Fixed, HDMI/DVI Mode Select, Fixed
//	{	0xB9	,	0x00	,	0x00	},	//	default	Fixed
	{	0xBA	,	0x08	,	0x08	},	//	custom	Clock Delay, Internal/External HDCP EEPROM, Fixed, Display AKSV, R Two Point Check
//	{	0xBB	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xC4	,	0x00	,	0x00	},	//	default	EDID Segment
//	{	0xC5	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xC7	,	0x00	,	0x00	},	//	default	Fixed, BKSV Count
//	{	0xC9	,	0x03	,	0x03	},	//	default	EDID Reread, EDID Tries
//	{	0xCD	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xCE	,	0x01	,	0x01	},	//	default	Fixed
//	{	0xCF	,	0x04	,	0x04	},	//	default	Fixed
//	{	0xD0	,	0x30	,	0x30	},	//	default	Enable DDR Negative Edge CLK Delay, DDR Negative Edge CLK Delay, Sync Pulse Select, Timing Generation Sequence, Fixed
//	{	0xD1	,	0xff	,	0xff	},	//	default	Fixed
//	{	0xD2	,	0x80	,	0x80	},	//	default	Fixed
//	{	0xD3	,	0x80	,	0x80	},	//	default	Fixed
//	{	0xD4	,	0x80	,	0x80	},	//	default	Fixed
//	{	0xD5	,	0x00	,	0x00	},	//	default	Fixed, High Refresh Rate Video, YCbCr Code Shift, Black Image
	{	0xD6	,	0xc0	,	0xc0	},	//	default	HPD Control, Fixed, TMDS CLK Soft Turn On, Fixed, Audio and Video Input Gating
//	{	0xD7	,	0x00	,	0x00	},	//	default	Hsync Placement
//	{	0xD8	,	0x00	,	0x00	},	//	default	Hsync Placement, Hsync Duration
//	{	0xD9	,	0x00	,	0x00	},	//	default	Hsync Duration, Vsync Placement
//	{	0xDA	,	0x00	,	0x00	},	//	default	Vsync Placement, Vsync Duration
//	{	0xDB	,	0x00	,	0x00	},	//	default	Vsync Duration
//	{	0xDC	,	0x00	,	0x00	},	//	default	Offset
//	{	0xDD	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xDE	,	0x10	,	0x10	},	//	default	Fixed, TMDS Clock Inversion, Fixed
//	{	0xDF	,	0x00	,	0x00	},	//	default	Fixed
	{	0xE0	,	0xD0	,	0xD0	},	//	default	Fixed
//	{	0xE1	,	0x78	,	0x78	},	//	default	CEC Map I2C Address
//	{	0xE2	,	0x00	,	0x00	},	//	default	Fixed, CEC Power Down
//	{	0xE3	,	0x00	,	0x00	},	//	default	Fixed
//	{	0xE4	,	0x60	,	0x60	},	//	default	Fixed
	{	0xF9	,	0x00	,	0x00	},	//	custom	Fixed
//	{	0xFA	,	0x00	,	0x00	},	//	default	Hsync Placement MSB, Fixed
//	{	0xFB	,	0x00	,	0x00	},	//	default	Hsync Delay MSB, Vsync Delay MSB, Width MSB, Height MSB, Low Refresh Rate (VIC Detection)
//	{	0xFC	,	0x00	,	0x00	},	//	default	R Checking Frequency, R Checking Position Delay, BCAPS Read Delay
//	{	0xFD	,	0x00	,	0x00	},	//	default	An Write Delay, AKSV Write Delay
//	{	0xFE	,	0x00	,	0x00	}	//	default	HDCP Start Delay
};


void configure_sd_rx(void);
void configure_sd_rx(void)
{
	//print("Setting up SD RX\r\n");
	i2c_write_reg(sd_rx_address, 0x58, 0x05); // 0x5 = output VS; 0x4 = output FIELD
	i2c_write_reg(sd_rx_address, 0xF9, 0x0B); // set coast mode VSYNC to 60Hz
	i2c_write_reg(sd_rx_address, 0x00, 0x50); // force input to NTSC M (5), Composite (0)
}

void configure_hdmi_tx_for_hd_input(void);
void configure_hdmi_tx_for_hd_input(void)
{
	//print("Setting up HDMI TX...\r\n");
	for(uint8_t i=0;i<tx_table_size;++i)
	{
		i2c_write_reg(hdmi_tx_address, tx_data[i].reg, tx_data[i].val_hd);
	}
	//print("  Finished.\r\n");
}

void configure_hdmi_tx_for_sd_input(void);
void configure_hdmi_tx_for_sd_input(void)
{
	//print("Setting up HDMI TX...\r\n");
	for(uint8_t i=0;i<tx_table_size;++i)
	{
		i2c_write_reg(hdmi_tx_address, tx_data[i].reg, tx_data[i].val_sd);
	}
	//print("  Finished.\r\n");
}

void probe_ddr_stick(void);
void probe_ddr_stick(void)
{
	int res;
	uint8_t reg04, reg05, reg07, reg0e, reg0f, reg20;

	print("Probing DDR RAM...\r\n");
	//register_dump(ddr_address);
	
	res = i2c_read_reg(ddr_address, 0x04, &reg04);
	if(res == SLAVE_OK)
	{
		i2c_read_reg(ddr_address, 0x05, &reg05);
		i2c_read_reg(ddr_address, 0x07, &reg07);
		i2c_read_reg(ddr_address, 0x0e, &reg0e);
		i2c_read_reg(ddr_address, 0x0f, &reg0f);
		i2c_read_reg(ddr_address, 0x20, &reg20);

		// reg04 bits 6 downto 4 = bank address bits - 3
		uint8_t bank_bits = 3 + ((reg04 & 0b01110000) >> 4);
		// reg05 bits 5 downto 3 = row address bits - 12
		uint8_t row_bits = 12 + ((reg05 & 0b00111000) >> 3);
		// reg05 bits 2 downto 0 = col address bits - 9
		uint8_t col_bits = 9 + (reg05 & 0b00000111);
		// reg07 bits 5 downto 3 = ranks - 1
		uint8_t ranks = 1 + ((reg07 & 0b00111000) >> 3);
		uint8_t rank_bits;
		if(ranks == 1)
			rank_bits = 0;
		else if(ranks == 2)
			rank_bits = 1;
		else if(ranks > 2 && ranks <= 4)
			rank_bits = 2;
		else
			rank_bits = 3;

		char outstr[] = "DDR DIMM found. Bit width of ranks, banks, rows, cols = XX, XX, XX, XX\r\n";
		byte_to_string(outstr+56, rank_bits);
		byte_to_string(outstr+60, bank_bits);
		byte_to_string(outstr+64, row_bits);
		byte_to_string(outstr+68, col_bits);
		print(outstr);
		char outstr2[] = "Total address width = XX bits (";
		uint8_t bits = rank_bits + bank_bits + row_bits + col_bits;
		byte_to_string(outstr2+22, bits);
		print(outstr2);
		if(bits == 30) 
			print("8GB)\r\n");
		else if(bits == 29)
			print("4GB)\r\n");
		else if(bits == 28)
			print("2GB)\r\n");
		else if(bits == 27)
			print("1GB)\r\n");
		else
			print("<512MB)\r\n");

		print("CAS latencies supported: ");
		if(reg0e & 0x01) print("4,");
		if(reg0e & 0x02) print("5,");
		if(reg0e & 0x04) print("6,");
		if(reg0e & 0x08) print("7,");
		if(reg0e & 0x10) print("8,");
		if(reg0e & 0x20) print("9,");
		if(reg0e & 0x40) print("10,");
		if(reg0e & 0x80) print("11,");
		if(reg0f & 0x01) print("12,");
		if(reg0f & 0x02) print("13,");
		if(reg0f & 0x04) print("14,");
		if(reg0f & 0x08) print("15,");
		if(reg0f & 0x10) print("16,");
		if(reg0f & 0x20) print("17,");
		if(reg0f & 0x40) print("18");
		print("\r\n");

		if(reg20 & 0x80)
			print("DIMM temperature sensor present\r\n");
		
	}else if(res == SLAVE_NAK)
	{
		print("NAK\r\n");
	}else if(res == SLAVE_NO_ACK)
	{
		print("NO ACK\r\n");
	}
	
}

void print_leveling_results()
{
	print("Leveling results:\r\n");
	for(int i=0;i<8;++i)
	{
		uint8_t val;
		i2c_read_reg(lanemate_address, 16+i, &val);
		uint8_t str[4] = "XX ";
		byte_to_string(str, val);
		print(str);
	}
	print("\r\n");
}
void print_register_content()
{
	print("Burst registers:\r\n");
	for(int i=31;i>=0;--i)
	{
		uint8_t val;
		i2c_read_reg(lanemate_address, 25+i, &val);
		uint8_t str[4] = "XX";
		byte_to_string(str, val);
		print(str);
	}
	print("\r\n");
	for(int i=63;i>=32;--i)
	{
		uint8_t val;
		i2c_read_reg(lanemate_address, 25+i, &val);
		uint8_t str[4] = "XX";
		byte_to_string(str, val);
		print(str);
	}
	print("\r\n");
}

uint32_t generate_address(unsigned char rank, unsigned char bank, uint16_t row, uint16_t col)
{
	uint32_t p1 = (rank>0?1:0) << 26;
	uint32_t p2 = (bank & 0b111) << 23;
	uint32_t p3 = (row & 0xFFFF) << 7;
	uint32_t p4 = (col & 0b1111111);
	return p1 | p2 | p3 | p4;
}
void address_to_bytes(const uint32_t addr, uint8_t *b3, uint8_t *b2, uint8_t *b1, uint8_t *b0)
{
	*b3 = (addr >> 24) & 0xFF;
	*b2 = (addr >> 16) & 0xFF;
	*b1 = (addr >>  8) & 0xFF;
	*b0 = (addr >>  0) & 0xFF;
}
void update_ram_pointers(uint32_t waddr, uint32_t raddr)
{
	uint8_t b3, b2, b1, b0;
	address_to_bytes(waddr, &b3, &b2, &b1, &b0);
	i2c_write_reg(lanemate_address,  7, b3);
	i2c_write_reg(lanemate_address,  8, b2);
	i2c_write_reg(lanemate_address,  9, b1);
	i2c_write_reg(lanemate_address, 10, b0);

	address_to_bytes(raddr, &b3, &b2, &b1, &b0);
	i2c_write_reg(lanemate_address, 11, b3);
	i2c_write_reg(lanemate_address, 12, b2);
	i2c_write_reg(lanemate_address, 13, b1);
	i2c_write_reg(lanemate_address, 14, b0);
}

volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

// Global state modified by onVSYNC -------------------------------------------

uint32_t frame_size = 0; // in ram columns
uint32_t mem_size_frames = 0;
uint32_t write_frame = 0;
uint32_t read_frame = 0;
uint32_t playback_hi = 0;
uint32_t playback_lo = 0;
int32_t frame_offset = 30; // this = write_frame - read_frame (ignoring wraparound)

const uint8_t MODE_RECORD = 3;
const uint8_t MODE_PLAYBACK_PLAY = 4;
const uint8_t MODE_PLAYBACK_PAUSE = 5;
uint8_t mode;

uint16_t counter = 0;
// ----------------------------------------------------------------------------

void getInputVideoProperties()
{
	// Measure the input video stream, if it exists.
	// Note that if an actual video source is not attached,
	// the frame size measurement registers are not accurate.
	uint8_t reg7,reg8,reg9,regA,reg6F;
	i2c_read_reg(hdmi_rx_address, 0x6F, &reg6F);
	bool cable_present = (reg6F & 0x01) > 0;

	if(cable_present)
	{
		i2c_read_reg(hdmi_rx_hdmi_address, 0x07, &reg7);
		i2c_read_reg(hdmi_rx_hdmi_address, 0x08, &reg8);
		uint16_t line_width = ((reg7 & 0b11111) << 8) | reg8;
		i2c_read_reg(hdmi_rx_hdmi_address, 0x09, &reg9);
		i2c_read_reg(hdmi_rx_hdmi_address, 0x0A, &regA);
		uint16_t field0_height = ((reg9 & 0b11111) << 8) | regA;

		if(line_width == 1280 && field0_height == 720)
		print("RX 720p\r\n");
		else if(line_width == 1920 && field0_height == 1080)
		print("RX 1080p\r\n");
		else
		{
			uint8_t str[64] = "RX XXXXxXXXX\r\n";
			byte_to_string(str+3, reg7 & 0b11111);
			byte_to_string(str+5, reg8);
			byte_to_string(str+8, reg9 & 0b11111);
			byte_to_string(str+10, regA);
			print(str);
		}
		
	}else
	{
		uint8_t freerun;
		i2c_read_reg(hdmi_rx_address, 0x00, &freerun);
		if(freerun == 0x13)
		print("RX free 720p\r\n");
		else if(freerun == 0x1E)
		print("RX free 1080p\r\n");
		else
		print("RX free other\r\n");
	}

	uint8_t vic_to_rx, actual_vic, aux;
	int ok = i2c_read_reg(hdmi_tx_address, 0x3E, &actual_vic);
	int ok2 = i2c_read_reg(hdmi_tx_address, 0x3F, &aux);
	int ok3 = i2c_read_reg(hdmi_tx_address, 0x3D, &vic_to_rx);
	if(vic_to_rx == 4)
	print("TX 720p\r\n");
	else if(vic_to_rx == 16)
	print("TX 1080p\r\n");
	else
	{
		uint8_t str[50] = "TX (XX, XX, XX)\r\n";
		byte_to_string(str+4, actual_vic >> 2);
		byte_to_string(str+8, vic_to_rx);
		byte_to_string(str+12, aux);
		print(str);
	}

	print("\r\n");

}

void onVSYNC(void)
{
	// Read and react to the control switches. GPIO 8 to 15 are captured in firmware
	// and written to register 26 bits 0 to 7.
	// GPIO8 : 3-position switch, "up"
	// GPIO9 : unused
	// GPIO10: 3-position switch, "down"
	// GPIO11: 0
	// GPIO12: 0
	// GPIO13: unused
	// GPIO14: encoder pushbutton ('1' = not pushed)
	// GPIO15: control box present

	uint8_t val;
	i2c_read_reg(lanemate_address, 26, &val);
	const bool bit0 = val & 0b00000001;
	const bool bit1 = val & 0b00000010;
	const bool bit2 = val & 0b00000100;
	const bool bit3 = val & 0b00001000;
	const bool bit4 = val & 0b00010000;
	const bool bit5 = val & 0b00100000;
	const bool bit6 = val & 0b01000000;
	const bool bit7 = val & 0b10000000;

	// Up = record
	// Middle = play
	// Down = pause
	uint8_t newmode;
	if(bit0 == true && bit2 == false)
		newmode = MODE_RECORD;
	else if(bit0 == false && bit2 == false)
		newmode = MODE_PLAYBACK_PLAY;
	else if(bit0 == false && bit2 == true)
		newmode = MODE_PLAYBACK_PAUSE;



	// Update state machine based on desired mode
	if(mode == MODE_RECORD)
	{
		if(newmode == MODE_PLAYBACK_PLAY || newmode == MODE_PLAYBACK_PAUSE)
		{
			// Enter playback mode. Here the write pointer doesn't move and so we play back
			// from the beginning up to one before the write pointer
			int32_t frame_tmp = ((int32_t)write_frame) - 1;
			if(frame_tmp < 0)
			frame_tmp += mem_size_frames;

			playback_hi = (uint32_t)frame_tmp;

			frame_tmp = ((int32_t)write_frame) - frame_offset - 1; // extra -1 because it's incremented below
			if(frame_tmp < 0)
			frame_tmp += mem_size_frames;

			playback_lo = (uint32_t)frame_tmp;
			read_frame = playback_lo;
		}else
		{
			// nothing to update if still in record mode
		}
	}else if(mode == MODE_PLAYBACK_PLAY || newmode == MODE_PLAYBACK_PAUSE)
	{
		if(newmode == MODE_RECORD)
		{
			// Exit playback mode
		}else
		{
			// nothing to update if still in playback mode
		}
	}
	mode = newmode;



	// Compute new pointers
	if(mode == MODE_RECORD)
	{
		write_frame++;
		if(write_frame >= mem_size_frames) // the last writable address is mem_size_frames-1
		{
			print("wrap\r\n");
			write_frame = 0;
		}
		int32_t read_frame_tmp = ((int32_t)write_frame) - frame_offset;
		if(read_frame_tmp < 0)
			read_frame_tmp += mem_size_frames;

		read_frame = (uint32_t)read_frame_tmp;
	}else if(mode == MODE_PLAYBACK_PLAY)
	{
		read_frame++;
		if(read_frame > playback_hi)
		{
			print("loop\r\n");
			read_frame = playback_lo;
		}
	}else if(mode == MODE_PLAYBACK_PAUSE)
	{
		// TODO: read_frame can be updated by the encoder
	}

	// This transaction takes about 2.7ms
	update_ram_pointers(write_frame * frame_size, read_frame * frame_size);

	if(counter == 60*5)
	{
		getInputVideoProperties();
		counter = 0;
	}else
	{
		++counter;
	}
}

int main (void)
{
	system_init();
	configure_usart();

	print("\r\n\n\nSoftware started\r\n");
	delay_init();




	configure_i2c_master();
	configure_hdmi_rx();
	configure_sd_rx();

	probe_ddr_stick();
	i2c_write_reg(lanemate_address, 15, 1); // run ddr init
	delay_cycles_ms(100);
	print_leveling_results();

	// When delay_application is cut out of the loop, I can directly 
	// talk to the MCB
	/*
	i2c_write_reg(lanemate_address, 0x05, 0x1e); // make sure transaction size is nonzero

	uint32_t mem_addr;
	for(int rank=0;rank<2;++rank)
	{
		for(int bank=0;bank<8;++bank)
		{
			uint8_t str[20] = "Rank: XX Bank: XX\r\n";
			byte_to_string(str+6, rank);
			byte_to_string(str+15, bank);
			print(str);

			mem_addr = generate_address(rank, bank, 0, 0);
			i2c_write_reg(lanemate_address,  7, (mem_addr >> 24) & 0xFF);
			i2c_write_reg(lanemate_address,  8, (mem_addr >> 16) & 0xFF);
			i2c_write_reg(lanemate_address,  9, (mem_addr >> 8) & 0xFF);
			i2c_write_reg(lanemate_address, 10, (mem_addr) & 0xFF);
			i2c_write_reg(lanemate_address, 24, 1); // run ddr mcb test
			delay_cycles_ms(1);
			print_register_content();
		}
	}
	*/
	//print("Waiting for FPGA to boot...\r\n");
	//delay_cycles_ms(10000);

	mode = MODE_RECORD;
	

	uint8_t source = 0; // 0=hd, 1=sd
	uint8_t testpattern = 0; // 0=off
	uint8_t readout_delay_hi;
	uint8_t readout_delay_lo;
	uint8_t transaction_size;
	uint8_t delay_enabled = 1;
	const uint32_t total_columns = 1 << 30; // TODO: get from ram probe

	if(source == 0)
	{
		configure_hdmi_tx_for_hd_input();
		bool full = true;
		if(full)
		{
			hdmi_rx_set_freerun_to_1080p60();
			// Transaction size is the number of 256-bit words to read/write at once. Must be even.
			// 1080p: readout delay = 1.5*1920 = 2880 = 0xB40, transaction size = full line = 0xB4
			readout_delay_hi = 0x0B;
			readout_delay_lo = 0x40;
			transaction_size = 0xB4;
			// Start with the size of the frame in bits then divide by the bus width (64) to get
			// the number of ram columns in a frame.
			frame_size = 1920*1080*24/64; // 777,600
		}else
		{
			hdmi_rx_set_freerun_to_720p60();
			// 720p: readout delay = 1.5*1280 = 1920 = 0x780, transaction size = full line = 0x78
			readout_delay_hi = 0x07;
			readout_delay_lo = 0x80;
			transaction_size = 0x78;
			frame_size = 1280*720*24/64;
		}
	}else
	{
		configure_hdmi_tx_for_sd_input();
		// SD is more complicated. A full line is 45 words, which is not even. I can increase
		// the buffer size to 2 lines to regain an even transaction size. The readout delay
		// needs to be 2 lines plus the time it takes for the transaction to complete (it could
		// be less but this is the conservative choice).
		// The total line length of 480i is 1716 clocks. 2 lines is 90 words, and there's a read
		// and write step, so 180 memory clocks plus some overhead. The pixel clock is 27MHz and
		// the memory clock is 200MHz, so the transaction will only take about 25 pixels.
		// Therefore I want a readout delay of about 1716+1716+25=0xD81. Here I rounded up to
		// account for overhead.
		readout_delay_hi = 0x0D;
		readout_delay_lo = 0x90;
		transaction_size = 90;
		// The SD bus is 8 bits, 1440 active clocks. Each field is 240 active lines.
		frame_size = 1440*240*8/64; // 43,200
	}
	// Note that I'm truncating here, it's not an integer natively
	mem_size_frames = total_columns / frame_size;
	// 1080p: 1380 (23s)
	// 720p: 3106 (51s)
	// 480i: 24,855 fields / 12,427 frames (414s)

	update_ram_pointers(write_frame * frame_size, read_frame * frame_size);

	i2c_write_reg(lanemate_address, 0x01, source);
	i2c_write_reg(lanemate_address, 0x02, testpattern);
	i2c_write_reg(lanemate_address, 0x03, readout_delay_hi);
	i2c_write_reg(lanemate_address, 0x04, readout_delay_lo);
	i2c_write_reg(lanemate_address, 0x05, transaction_size);
	i2c_write_reg(lanemate_address, 0x06, delay_enabled);

	
	config_interrupts();

	uint8_t res = 0;


	uint32_t ticks_per_second = system_gclk_gen_get_hz(GCLK_GENERATOR_0);
	uint32_t ticks_between_interrupts = ticks_per_second / 1;
	SysTick_Config(ticks_between_interrupts);
	uint8_t cycle_count = 0;

	while(1)
	{
		if(handle_event)
		{
			handle_event = false;
			/*
			testpattern++;
			if(testpattern > 4+7)
				testpattern = 4;
			i2c_write_reg(lanemate_address, 0x02, testpattern);
			*/
			/*
			write_frame++; read_frame++;
			if(write_frame > mem_size_frames)
			{
				write_frame = 1;
				read_frame = 0;
			}
			update_ram_pointers(write_frame * frame_size, read_frame * frame_size);
			uint8_t str[15] = "WXXXX, RXXXX\r\n";
			byte_to_string(str+1, (write_frame >> 8) & 0xFF);
			byte_to_string(str+3, (write_frame >> 0) & 0xFF);
			byte_to_string(str+8, (read_frame >> 8) & 0xFF);
			byte_to_string(str+10, (read_frame >> 0) & 0xFF);
			print(str);
			*/
			if(cycle_count == 10)
			{
				/*
				if(res == 0)
				{
					print("Changing freerun to 1080p60\r\n");
					hdmi_rx_set_freerun_to_1080p60();
					res = 1;
				}else
				{
					print("Changing freerun to 720p60\r\n");
					hdmi_rx_set_freerun_to_720p60();
					res = 0;
				}
				// changing resolution changes the clock frequency,
				// so I need to trigger dcm reset, which can be
				// done by writing to the video source register
				i2c_write_reg(lanemate_address, 0x01, source);
				*/

				/*
				if(source == 1)
				{
					source = 0;
					configure_hdmi_tx_for_hd_input();
				}
				else
				{
					source = 1;
					configure_hdmi_tx_for_sd_input();
				}
				i2c_write_reg(lanemate_address, 0x01, source);
				*/

				/*
				delay_enabled = (delay_enabled > 0)? 0 : 1;
				i2c_write_reg(lanemate_address, 0x06, delay_enabled);
				if(delay_enabled) print("Delay enabled\r\n");
				else print("Delay disabled\r\n");
				*/

				/*
				if(addr_w_L >= 180)
				{
					print("Reset\r\n");
					addr_w_L = 0;
				}
				else
				{
					addr_w_L += 45;
				}
				i2c_write_reg(lanemate_address, 10, addr_w_L);
				*/

				cycle_count = 0;
			}else
				++cycle_count;
			


			/*
			// Measure the input video stream, if it exists.
			// Note that if an actual video source is not attached,
			// the frame size measurement registers are not accurate.
			uint8_t reg7,reg8,reg9,regA,reg6F;
			i2c_read_reg(hdmi_rx_address, 0x6F, &reg6F);
			bool cable_present = (reg6F & 0x01) > 0;

			if(cable_present)
			{
				i2c_read_reg(hdmi_rx_hdmi_address, 0x07, &reg7);
				i2c_read_reg(hdmi_rx_hdmi_address, 0x08, &reg8);
				uint16_t line_width = ((reg7 & 0b11111) << 8) | reg8;
				i2c_read_reg(hdmi_rx_hdmi_address, 0x09, &reg9);
				i2c_read_reg(hdmi_rx_hdmi_address, 0x0A, &regA);
				uint16_t field0_height = ((reg9 & 0b11111) << 8) | regA;

				if(line_width == 1280 && field0_height == 720)
				print("HDMI RX: receiving 720p\r\n");
				else if(line_width == 1920 && field0_height == 1080)
				print("HDMI RX: receiving 1080p\r\n");
				else
				print("HDMI RX: receiving unsupported video\r\n");
			}else
			{
				uint8_t freerun;
				i2c_read_reg(hdmi_rx_address, 0x00, &freerun);
				if(freerun == 0x13)
				print("HDMI RX: free running at 720p\r\n");
				else if(freerun == 0x1E)
				print("HDMI RX: free running at 1080p\r\n");
				else
				print("HDMI RX: free running at other resolution\r\n");
			}

			
			uint8_t status1, status2, status3;
			i2c_read_reg(sd_rx_address, 0x10, &status1);
			i2c_read_reg(sd_rx_address, 0x12, &status2);
			i2c_read_reg(sd_rx_address, 0x13, &status3);
			bool in_lock = status1 & 0x01;
			uint8_t ad_result = (status1 & 0x70) >> 4;
			if(in_lock)
			{
				print("SD RX: ");
				switch(ad_result)
				{
				case 0:
					print("NTSC M/J");
					break;
				case 1:
					print("NTSC 4.43");
					break;
				case 2:
					print("PAL M");
					break;
				case 3:
					print("PAL 60");
					break;
				case 4:
					print("PAL B/G/H/I/D");
					break;
				case 5:
					print("SECAM");
					break;
				case 6:
					print("PAL Combination M");
					break;
				case 7:
					print("SECAM 525");
					break;
				}
				print("\r\n");
			}else
			{
				print("SD RX: free running\r\n");
			}
			



			uint8_t vic_to_rx, actual_vic, aux;
			int ok = i2c_read_reg(hdmi_tx_address, 0x3E, &actual_vic);
			int ok2 = i2c_read_reg(hdmi_tx_address, 0x3F, &aux);
			int ok3 = i2c_read_reg(hdmi_tx_address, 0x3D, &vic_to_rx);
			if(vic_to_rx == 4)
				print("HDMI TX: detected 720p60\r\n");
			else if(vic_to_rx == 16)
				print("HDMI TX: detected 1080p60\r\n");
			else
			{
				uint8_t str[50] = "HDMI TX: VIC (detected, used, aux) = XX, XX, XX\r\n";
				byte_to_string(str+37, actual_vic >> 2);
				byte_to_string(str+41, vic_to_rx);
				byte_to_string(str+45, aux);
				print(str);
			}

			print("\r\n");
			*/

			

		}
	}
	
}
