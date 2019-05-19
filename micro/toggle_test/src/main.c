#include <asf.h>
#include <samd10d14as.h> // this is redundant and just here to remind myself of the part #
#include <string.h>
#include "utils.h"
#include "i2c.h"
#include "uart.h"
#include "hdmi_rx.h"

/*
#define TEST_PIN PIN_PA24
void config_test_pin(void);
void config_test_pin(void)
{
	struct port_config pin_conf;
	port_get_config_defaults(&pin_conf);

	pin_conf.direction  = PORT_PIN_DIR_OUTPUT;
	port_pin_set_config(TEST_PIN, &pin_conf);
	port_pin_set_output_level(TEST_PIN, LOW);
}
*/

const uint16_t hdmi_tx_address = 0x72 >> 1;
const uint16_t sd_rx_address = 0x40 >> 1;

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
}

void configure_hdmi_tx(void);
void configure_hdmi_tx(void)
{
	//print("Setting up HDMI TX...\r\n");
	for(uint8_t i=0;i<tx_table_size;++i)
	{
		i2c_write_reg(hdmi_tx_address, tx_data[i].reg, tx_data[i].val_hd);
	}
	//print("  Finished.\r\n");
}



volatile bool handle_event = false;

void SysTick_Handler(void)
{
	handle_event = true;
}

int main (void)
{
	system_init();
	configure_usart();

	//print("\r\n\n\nSoftware started\r\n");
	delay_init();


	print("Waiting for FPGA to boot...\r\n");
	delay_cycles_ms(1000);


	configure_i2c_master();
	configure_hdmi_rx();
	configure_sd_rx();
	configure_hdmi_tx();

	
	//config_test_pin();
	//port_pin_toggle_output_level(TEST_PIN);

	//print("Reading out FPGA registers\r\n");
	const uint16_t lanemate_address = 0b0101100;
	const uint16_t regs[8] = {0,1,2,3,4,5,6,7};
	for(int i=0;i<8;++i)
	{
		uint8_t b;
		int ok = i2c_read_reg(lanemate_address, regs[i], &b);
		if(ok == SLAVE_OK)
		{
			uint8_t buf[3];
			byte_to_string(buf, b);
			buf[2] = '\0';
			print(buf);
		}else if(ok == SLAVE_NAK)
		print("NAK");
		else if(ok == SLAVE_NO_ACK)
		print("NO ACK");
		print("\r\n");
	}

	uint8_t source = 0;
	i2c_write_reg(lanemate_address, 0x01, source);
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

			if(cycle_count == 15)
			{
				if(res == 0)
				{
					//print("Changing freerun to 1080p60\r\n");
					//hdmi_rx_set_freerun_to_1080p60();
					res = 1;
				}else
				{
					//print("Changing freerun to 720p60\r\n");
					//hdmi_rx_set_freerun_to_720p60();
					res = 0;
				}
				// changing resolution changes the clock frequency,
				// so I need to trigger dcm reset, which can be
				// done by writing to the video source register
				i2c_write_reg(lanemate_address, 0x01, source);

				cycle_count = 0;
			}else
				++cycle_count;
			



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


			

		}
	}
	
}
