
#include "../tp2.h"


void sepia_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size)
{
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    unsigned int suma;
    float parte;
    //unsigned int parteEnInt;
    unsigned int tmp;

    for (int i = 0; i < filas; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            bgra_t *p_d = (bgra_t*) &dst_matrix[i][j * 4];
            bgra_t *p_s = (bgra_t*) &src_matrix[i][j * 4];
            //*p_d = *p_s;

            suma  = p_s->b;
            suma += p_s->g;
            suma += p_s->r;

            parte = suma * 0.1f;

            tmp = 2 * parte;
            p_d->b = tmp > 255 ? 255 : tmp;
            tmp = 3 * parte;
            p_d->g = tmp > 255 ? 255 : tmp;
            tmp = 5 * parte;
            p_d->r = tmp > 255 ? 255 : tmp;
            p_d->a = p_s->a;

        }
    }	//COMPLETAR
}



