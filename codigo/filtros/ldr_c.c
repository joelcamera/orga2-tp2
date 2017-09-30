
#include "../tp2.h"

#define MIN(x,y) ( x < y ? x : y )
#define MAX(x,y) ( x > y ? x : y )

#define P 2
#define MAXSUMA 4876875 //5*5*255*3*255

void ldr_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size,
	int alpha)
{
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

    for (int i = P; i < filas-P; i++)
    {
        for (int j = P; j < cols-P; j++)
        {

            bgra_t *p_d = (bgra_t*) &dst_matrix[i][j * 4];
            long sumargb = 0;
            for(int k = -P; k <= P; k++) {
                for(int l = -P; l <= P; l++) {
                    bgra_t *p_s = (bgra_t*) &src_matrix[i-k][(j-l) * 4];
                    sumargb += p_s->r + p_s->g + p_s->b;
                }
            }

            sumargb *= alpha;
            bgra_t *p_s = (bgra_t*) &src_matrix[i][j * 4];
            long sumargbCanalR = p_s->r+(sumargb * p_s->r) / MAXSUMA;
            long sumargbCanalG = p_s->g+(sumargb * p_s->g) / MAXSUMA;
            long sumargbCanalB = p_s->b+(sumargb * p_s->b) / MAXSUMA;
            p_d->a = p_s->a;
            p_d->r = MIN(MAX(sumargbCanalR, 0), 255);
            p_d->g = MIN(MAX(sumargbCanalG, 0), 255);
            p_d->b = MIN(MAX(sumargbCanalB, 0), 255);
        }
    }
}


