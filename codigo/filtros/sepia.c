
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

#define SEPIA_DEF(func_name) void func_name (unsigned char *src, unsigned char *dst, int cols, int filas, \
                      int src_row_size, int dst_row_size, int alfa)

SEPIA_DEF(sepia_asm);
SEPIA_DEF(sepia_asm2);
SEPIA_DEF(sepia_c);


typedef void (sepia_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int);


int alfa;

void leer_params_sepia(configuracion_t *config, int argc, char *argv[]) {
	config->extra_config = &alfa;
    alfa = atoi(argv[argc - 1]);
}

void aplicar_sepia(configuracion_t *config)
{
	sepia_fn_t *sepia = SWITCH_C_ASM ( config, sepia_c, sepia_asm ) ;
	if( config->tipo_filtro == FILTRO_ASM && config->version == 2) sepia = sepia_asm2;

	buffer_info_t info = config->src;
	sepia(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding, alfa);

}

void ayuda_sepia()
{
	printf ( "       * sepia\n" );
	printf ( "           Parámetros     : \n"
	         "                         ninguno\n");
	printf ( "           Ejemplo de uso : \n"
             "                         sepia -i c bgr.bmp\n");
}


