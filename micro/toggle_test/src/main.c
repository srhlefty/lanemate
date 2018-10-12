#include <asf.h>

#define TEST_PIN PIN_PA24

void SysTick_Handler(void)
{
	port_pin_toggle_output_level(TEST_PIN);
}

static void config_test_pin(void)
{
	struct port_config pin_conf;
	port_get_config_defaults(&pin_conf);

	pin_conf.direction  = PORT_PIN_DIR_OUTPUT;
	port_pin_set_config(TEST_PIN, &pin_conf);
	port_pin_set_output_level(TEST_PIN, LOW);
}

int main (void)
{
	system_init();

	SysTick_Config(system_gclk_gen_get_hz(GCLK_GENERATOR_0));
	
	config_test_pin();
	
	while(1) {}
}
